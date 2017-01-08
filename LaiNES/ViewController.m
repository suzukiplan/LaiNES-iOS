//
//  ViewController.m
//  LaiNES
//
//  Created by Yoji Suzuki on 2017/01/06.
//  Copyright © 2017年 SUZUKI PLAN. All rights reserved.
//

#import <pthread.h>
#import <mach/mach_time.h>
#import "ViewController.h"
#import "NESview.h"
#import "PADView.h"
#import "nes-core.h"

#define BUTTON_SIZE 36
#define MARGIN 6
#define MENU_WIDTH 240

@interface ViewController ()
@property (readwrite) NSUserDefaults* pref;
@property (readwrite) CGFloat width;
@property (readwrite) CGFloat height;
@property (readwrite) UIView* headerView;
@property (readwrite) UIView* gameFrame;
@property (readwrite) NESView* nesView;
@property (readwrite) PADView* padView;
@property (readwrite) UIView* menuOutView;
@property (readwrite) UIView* menuView;
@property (readwrite) pthread_t tickExecutor;
@end

static volatile BOOL alive;

// execute tick in 1/60sec
static void* tick_executor(void* args) {
    NSLog(@"tick-executor start");
    int s[] = {
        16000,
        17000,
        17000
    };
    int i = 0;
    uint64_t st;
    mach_timebase_info_data_t tb;
    mach_timebase_info(&tb);
    int df;
    while (alive) {
        st = mach_absolute_time();
        nes_tick(PAD_STATUS, 0);
        df = (int)(((mach_absolute_time() - st) / tb.denom) / 1000);
        if (df < s[i]) usleep(s[i] - df);
        i++;
        i %= 3;
    }

    NSLog(@"tick-executor end");
    return NULL;
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _pref = [NSUserDefaults standardUserDefaults];
    _width = [UIScreen mainScreen].bounds.size.width;
    _height = [UIScreen mainScreen].bounds.size.height;
    [self.view setBackgroundColor:[UIColor colorWithRed:0.1875f green:0.246f blue:0.625f alpha:1.0f]];

    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0,20,_width,BUTTON_SIZE+MARGIN*2)];
    [_headerView setBackgroundColor:[UIColor colorWithRed:0.1875f green:0.246f blue:0.825f alpha:1.0f]];
    UIButton* menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setImage:[UIImage imageNamed:@"ic_menu_white_24dp.png"] forState:UIControlStateNormal];
    [menuButton setFrame:CGRectMake(_width-BUTTON_SIZE-MARGIN, MARGIN, BUTTON_SIZE, BUTTON_SIZE)];
    [menuButton addTarget:self action:@selector(openMenu) forControlEvents:UIControlEventTouchDown];
    [_headerView addSubview:menuButton];
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN, MARGIN, _width - BUTTON_SIZE - MARGIN*4, BUTTON_SIZE)];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    titleLabel.text = @"LaiNES for iPhone";
    [_headerView addSubview:titleLabel];
    [self.view addSubview:_headerView];

    _gameFrame = [[UIView alloc] initWithFrame:CGRectMake(0, 20 + BUTTON_SIZE + MARGIN * 2, _width, _width / 4 * 3)];
    [_gameFrame setBackgroundColor:[UIColor blackColor]];
    {
        CGFloat x, y, width, height;
        height = _gameFrame.frame.size.height;
        width = height / 15.0f * 16.0f;
        x = (_gameFrame.frame.size.width - width) / 2;
        y = 0;
        _nesView = [[NESView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        [_gameFrame addSubview:_nesView];
    }
    [self.view addSubview:_gameFrame];

    {
        int y = _gameFrame.frame.origin.y + _gameFrame.frame.size.height;
        _padView = [[PADView alloc] initWithFrame:CGRectMake(0, y, _width, _height - y)];
    }
    [self.view addSubview:_padView];
    
    _menuOutView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _width, _height)];
    [_menuOutView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)]];
    [self.view addSubview:_menuOutView];
    [_menuOutView setHidden:YES];

    _menuView = [[UIView alloc] initWithFrame:CGRectMake(-MENU_WIDTH, 0, MENU_WIDTH, _height)];
    [_menuView setBackgroundColor:[UIColor colorWithRed:0.1875f green:0.246f blue:0.825f alpha:0.8f]];
    [self.view addSubview:_menuView];

    UIButton* loadRomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    loadRomButton.frame = CGRectMake(MARGIN, 20 + MARGIN, MENU_WIDTH - MARGIN * 2, 30);
    [loadRomButton setTitle:@"Load ROM file" forState:UIControlStateNormal];
    [loadRomButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [loadRomButton addTarget:self action:@selector(loadRom) forControlEvents:UIControlEventTouchDown];
    [_menuView addSubview:loadRomButton];

    [self startTickExecutor];
}

- (void)openMenu {
    [_menuOutView setHidden:NO];
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        _menuView.frame = CGRectMake(0, 0, MENU_WIDTH, _height);
        _menuOutView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f];
    } completion:^(BOOL finished) {
    }];
}

- (void)closeMenu {
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        _menuView.frame = CGRectMake(-MENU_WIDTH, 0, MENU_WIDTH, _height);
        _menuOutView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
    } completion:^(BOOL finished) {
        [_menuOutView setHidden:YES];
    }];
}

- (void)loadRom {
    [self closeMenu];
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Load ROM file"
                                                                              message: @"Input URL"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"url";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.textContentType = UITextContentTypeURL;
        textField.text = [_pref stringForKey:@"romUrl"];
        if (!textField.text || [textField.text isEqualToString:@""]) {
            textField.text = @"http://0.0.0.0:1234/sample.nes";
        }
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString* url = alertController.textFields[0].text;
        [_pref setObject:url forKey:@"romUrl"];
        [self loadRomWithURL:[NSURL URLWithString:url]];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)loadRomWithURL:(NSURL*)url {
    [self downloadWithURL:url success:^(NSData* data) {
        if (![_nesView loadRomWithData:data]) {
            [self showErrorDialog:@"Invalid file"];
        }
    } failure:^(NSError* error) {
        [self showErrorDialog:[error localizedDescription]];
    }];
}

-(void)downloadWithURL:(NSURL*)url success:(void (^)(NSData* data))success failure:(void(^)(NSError* error))failure
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data || data.length < 1) {
                failure(error);
            } else {
                success(data);
            }
        });
    }];
    [dataTask resume];
}

-(void)startTickExecutor {
    pthread_t tid;
    alive = YES;
    pthread_create(&tid, NULL, tick_executor, NULL);
    struct sched_param param;
    memset(&param,0,sizeof(param));
    param.sched_priority = 46;
    pthread_setschedparam(tid,SCHED_OTHER,&param);
    _tickExecutor = tid;
}

-(void)showErrorDialog:(NSString*)message {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"OK action");
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:^{
    }];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
