//
//  nes-core.h
//  LaiNES
//
//  Created by Yoji Suzuki on 2017/01/07.
//  Copyright © 2017年 SUZUKI PLAN. All rights reserved.
//

#ifndef nes_core_h
#define nes_core_h

#include "common.hpp"

#define VRAM_WIDTH 256
#define VRAM_HEIGHT 240

#ifdef __cplusplus
extern "C" {
#endif
    extern unsigned short* nes_vram;
    void nes_init();
    void nes_deinit();
    bool nes_loadRom(const void* rom, size_t size);
    void nes_tick(u8 keyStateP1, u8 keyStateP2);
    void nes_vram_copy(u16* buffer);
    int nes_fps();
#ifdef __cplusplus
};
#endif

#endif /* nes_core_h */
