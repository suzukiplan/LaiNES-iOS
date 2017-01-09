#include <pthread.h>
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#include <unistd.h>
#include <stdio.h>
#include "cartridge.hpp"
#include "apu.hpp"
#include "cpu.hpp"
#include "hal.hpp"
#include "nes-core.h"

#define MAX_PLAYER 2
#define KEY_A 1
#define KEY_B 2
#define KEY_SELECT 4
#define KEY_START 8
#define KEY_UP 16
#define KEY_DOWN 32
#define KEY_LEFT 64
#define KEY_RIGHT 128

static pthread_mutex_t _mt;
static pthread_mutex_t _mt2;

static void* _rom;
static pthread_t _tid;
static volatile bool _alive;
static volatile bool _run;

static u8 _keyState[MAX_PLAYER];
static u16 _pixels[122880 / 2];
static u16 _vram[122880 / 2];

#define kOutputBus 0
#define kInputBus 1
#define BUFNUM 2

#define APU_BUFFER_SIZE 19200
#define OUT_BUFFER_SIZE 8820
#define OUT_BUFFER_SIZE_DIV2 4410

#define QUEUE_SIZE 163840

typedef ALvoid AL_APIENTRY (*alBufferDataStaticProcPtr)(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);

struct AL {
    ALCdevice* sndDev;
    ALCcontext* sndCtx;
    ALuint sndABuf;
    ALuint sndASrc;
    alBufferDataStaticProcPtr alBufferDataStaticProc;
};
static struct AL _al;
static pthread_t _snd;
static short _q[QUEUE_SIZE];
static int _qsize;
static unsigned char _silent[OUT_BUFFER_SIZE];
static int _abp[OUT_BUFFER_SIZE_DIV2];

static void* _exec_frame_thread(void* args);
static void _lock();
static void _unlock();
static void _lock2();
static void _unlock2();

static int _init_al();
static void _term_al();
static void* _sound_thread(void* context);
static void _enqueue(const void* buffer);

static int _fps;

extern "C" void nes_init() {
    pthread_mutex_init(&_mt, NULL);
    pthread_mutex_init(&_mt2, NULL);
    double ratio = ((double)APU_BUFFER_SIZE) / OUT_BUFFER_SIZE;
    int i;
    for (i = 0; i < OUT_BUFFER_SIZE_DIV2; i++) {
        _abp[i] = (int)(i * ratio);
    }
    APU::init();
    _alive = true;
    _run = false;
    pthread_create(&_tid, NULL, _exec_frame_thread, NULL);
    _init_al();
    pthread_create(&_snd, NULL, _sound_thread, NULL);
}

extern "C" void nes_deinit() {
    _alive = false;
    void* ret;
    pthread_join(_tid, &ret);
    pthread_join(_snd, &ret);
    _term_al();
    pthread_mutex_destroy(&_mt);
    pthread_mutex_destroy(&_mt2);
}

extern "C" bool nes_loadRom(const void* rom, size_t size) {
    printf("loading ROM file (%lu bytes)", size);
    bool b;
    _lock2();
    if (_rom) free(_rom);
    _rom = malloc(size);
    if (_rom) {
        memcpy(_rom, rom, size);
        Cartridge::load(_rom, (int)size);
        b = Cartridge::loaded();
    }
    _unlock2();
    return b;
}

extern "C" int nes_fps() {
    return _fps;
}

extern "C" void nes_tick(u8 keyStateP1, u8 keyStateP2) {
    static time_t t;
    static int frame;

    // load check
    if (!Cartridge::loaded()) return;
    
    // sync previous frame
    while (_alive && _run) usleep(100);
    _lock();
    memcpy(_vram, _pixels, sizeof(_vram));
    _unlock();
    
    // execute next frame
    _keyState[0] = keyStateP1;
    _keyState[1] = keyStateP2;
    _run = true;

    frame++;
    time_t now = time(NULL);
    if (t != now) {
        t = now;
        _fps = frame;
        frame = 0;
    }
}

extern "C" void nes_vram_copy(u16* buffer) {
    _lock();
    memcpy(buffer, _vram, sizeof(_vram));
    _unlock();
}

namespace HAL {
    u8 get_joypad_state(int n) {
        return _keyState[n];
    }
    void new_frame(u16* pixels) {
        memcpy(_pixels, pixels, 122880);
    }
    void new_samples(const blip_sample_t* samples, size_t count) {
        _enqueue(samples);
    }
}

static void* _exec_frame_thread(void* args)
{
    while (true) {
        while (_alive && !_run) {
            usleep(300);
        }
        if (!_alive) break;
        _lock2();
        CPU::run_frame();
        _unlock2();
        _run = false;
    }
    return NULL;
}

static void _lock()
{
    pthread_mutex_lock(&_mt);
}

static void _unlock()
{
    pthread_mutex_unlock(&_mt);
}

static void _lock2()
{
    pthread_mutex_lock(&_mt2);
}

static void _unlock2()
{
    pthread_mutex_unlock(&_mt2);
}

static int _init_al()
{
    _al.sndDev = alcOpenDevice(NULL);
    if (NULL == _al.sndDev) {
        _term_al();
        return -1;
    }
    _al.sndCtx = alcCreateContext(_al.sndDev, NULL);
    if (NULL == _al.sndCtx) {
        _term_al();
        return -1;
    }
    if (!alcMakeContextCurrent(_al.sndCtx)) {
        _term_al();
        return -1;
    }
    _al.alBufferDataStaticProc = (alBufferDataStaticProcPtr)alcGetProcAddress(NULL, (const ALCchar*)"alBufferDataStatic");
    alGenSources(1, &(_al.sndASrc));
    return 0;
}

static void _term_al()
{
    if (_al.sndCtx) {
        alcDestroyContext(_al.sndCtx);
        _al.sndCtx = NULL;
    }
    if (_al.sndDev) {
        alcCloseDevice(_al.sndDev);
        _al.sndDev = NULL;
    }
}

static void _enqueue(const void* buffer)
{
    int i;
    const short* f = (const short*)buffer;
    for (i = 0; i < OUT_BUFFER_SIZE / 2; i++) {
        _q[_qsize++] = f[_abp[i]];
    }
}

static void* _dequeue(int* size)
{
    static unsigned char result[2][QUEUE_SIZE];
    static int page;
    int p = page;
    *size = _qsize * 2;
    if (*size) {
        memcpy(result[p], _q, *size);
        _qsize = 0;
        page = 1 - page;
    }
    return result[p];
}

static void* _sound_thread(void* context)
{
    ALint st;
    int size;
    void* buffer;
    while (_alive) {
        alGetSourcei(_al.sndASrc, AL_BUFFERS_QUEUED, &st);
        if (st < BUFNUM) {
            alGenBuffers(1, &_al.sndABuf);
        } else {
            alGetSourcei(_al.sndASrc, AL_SOURCE_STATE, &st);
            if (st != AL_PLAYING) {
                alSourcePlay(_al.sndASrc);
            }
            while (alGetSourcei(_al.sndASrc, AL_BUFFERS_PROCESSED, &st), st == 0) {
                usleep(1000);
            }
            alSourceUnqueueBuffers(_al.sndASrc, 1, &_al.sndABuf);
            alDeleteBuffers(1, &_al.sndABuf);
            alGenBuffers(1, &_al.sndABuf);
        }
        buffer = _dequeue(&size);
        if (size < 1) {
            buffer = _silent;
            size = (int)sizeof(_silent);
        }
        alBufferData(_al.sndABuf, AL_FORMAT_MONO16, buffer, size, 44100);
        alSourceQueueBuffers(_al.sndASrc, 1, &_al.sndABuf);
    }
    do {
        usleep(1000);
        alGetSourcei(_al.sndASrc, AL_SOURCE_STATE, &st);
    } while (st == AL_PLAYING);
    return NULL;
}
