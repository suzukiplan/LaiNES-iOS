//
//  PADView.m
//  LaiNES
//
//  Created by Yoji Suzuki on 2017/01/08.
//  Copyright © 2017年 SUZUKI PLAN. All rights reserved.
//

#import "PADView.h"
#import <math.h>

int PAD_STATUS;

struct _PADStatus {
    BOOL up;
    BOOL down;
    BOOL left;
    BOOL right;
    BOOL a;
    BOOL b;
    BOOL start;
    BOOL select;
};
typedef struct _PADStatus PADStatus;

#define PADDING 10
#define BUTTON_SIZE 80
#define START_AREA_HEIGHT 70
#define START_AREA_WIDTH 192
#define START_WIDTH 96
#define START_HEIGHT 48

#define TAG_PAD_AREA 0x1001
#define TAG_BUTTON_AREA 0x1002

@interface PADView()
@property (readwrite) UIImageView* cursor;
@property (readwrite) UIImage* upOff;
@property (readwrite) UIImage* upOn;
@property (readwrite) UIImageView* up;
@property (readwrite) UIImage* downOff;
@property (readwrite) UIImage* downOn;
@property (readwrite) UIImageView* down;
@property (readwrite) UIImage* leftOff;
@property (readwrite) UIImage* leftOn;
@property (readwrite) UIImageView* left;
@property (readwrite) UIImage* rightOff;
@property (readwrite) UIImage* rightOn;
@property (readwrite) UIImageView* right;
@property (readwrite) UIView* cursorTouchArea;
@property (readwrite) UIImage* aOff;
@property (readwrite) UIImage* aOn;
@property (readwrite) UIImageView* a;
@property (readwrite) UIImage* bOff;
@property (readwrite) UIImage* bOn;
@property (readwrite) UIImageView* b;
@property (readwrite) UIView* buttonTouchArea;
@property (readwrite) UIButton* start;
@property (readwrite) UIButton* select;
@property (readwrite) PADStatus padStatus;
@end

@implementation PADView

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ([super initWithCoder:aDecoder]) {
        [self _init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self _init];
    }
    return self;
}

-(id)init {
    if ([super init]) {
        [self _init];
    }
    return self;
}

-(void)_init {
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    int x, y, w, h;

    _cursor = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pad_bg.png"]];
    _cursor.contentMode = UIViewContentModeScaleToFill;
    w = width * 10 / 17 - PADDING * 2;
    h = w;
    x = PADDING;
    y = (height - h - START_AREA_HEIGHT) / 2;
    _cursor.frame = CGRectMake(x, y, w, h);

    w /= 3;
    h = w;

    _upOff = [UIImage imageNamed:@"pad_up_off.png"];
    _upOn = [UIImage imageNamed:@"pad_up_on.png"];
    _up = [[UIImageView alloc] initWithImage:_upOff];
    _up.contentMode = UIViewContentModeScaleToFill;
    x = (_cursor.frame.size.width - w) / 2;
    y = 0;
    _up.frame = CGRectMake(x, y, w, h);
    [_cursor addSubview:_up];

    _downOff = [UIImage imageNamed:@"pad_down_off.png"];
    _downOn = [UIImage imageNamed:@"pad_down_on.png"];
    _down = [[UIImageView alloc] initWithImage:_downOff];
    _down.contentMode = UIViewContentModeScaleToFill;
    y = _cursor.frame.size.height - h;
    _down.frame = CGRectMake(x, y, w, h);
    [_cursor addSubview:_down];

    _leftOff = [UIImage imageNamed:@"pad_left_off.png"];
    _leftOn = [UIImage imageNamed:@"pad_left_on.png"];
    _left = [[UIImageView alloc] initWithImage:_leftOff];
    _left.contentMode = UIViewContentModeScaleToFill;
    x = 0;
    y = (_cursor.frame.size.height - h) / 2;
    _left.frame = CGRectMake(x, y, w, h);
    [_cursor addSubview:_left];

    _rightOff = [UIImage imageNamed:@"pad_right_off.png"];
    _rightOn = [UIImage imageNamed:@"pad_right_on.png"];
    _right = [[UIImageView alloc] initWithImage:_rightOff];
    _right.contentMode = UIViewContentModeScaleToFill;
    x = _cursor.frame.size.width - w;
    _right.frame = CGRectMake(x, y, w, h);
    [_cursor addSubview:_right];
    [self addSubview:_cursor];

    _cursorTouchArea = [[UIView alloc] initWithFrame:_cursor.frame];
    _cursorTouchArea.tag = TAG_PAD_AREA;
    [self addSubview:_cursorTouchArea];

    x = width - BUTTON_SIZE - PADDING;
    y = (height - BUTTON_SIZE - START_AREA_HEIGHT) / 2 - (BUTTON_SIZE + PADDING) / 2;
    w = BUTTON_SIZE;
    h = w;
    _aOff = [UIImage imageNamed:@"button_a_off.png"];
    _aOn = [UIImage imageNamed:@"button_a_on.png"];
    _a = [[UIImageView alloc] initWithImage:_aOff];
    _a.contentMode = UIViewContentModeScaleToFill;
    _a.frame = CGRectMake(x, y, w, h);
    [self addSubview:_a];

    x = width - BUTTON_SIZE - PADDING;
    y = (height - BUTTON_SIZE - START_AREA_HEIGHT) / 2 + (BUTTON_SIZE + PADDING) / 2;
    w = BUTTON_SIZE;
    h = w;
    _bOff = [UIImage imageNamed:@"button_b_off.png"];
    _bOn = [UIImage imageNamed:@"button_b_on.png"];
    _b = [[UIImageView alloc] initWithImage:_bOff];
    _b.contentMode = UIViewContentModeScaleToFill;
    _b.frame = CGRectMake(x, y, w, h);
    [self addSubview:_b];

    x = _a.frame.origin.x;
    y = _a.frame.origin.y;
    w = BUTTON_SIZE;
    h = BUTTON_SIZE * 2 + PADDING;
    _buttonTouchArea = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    _buttonTouchArea.tag = TAG_BUTTON_AREA;
    [self addSubview:_buttonTouchArea];
    
    x = (width - START_AREA_WIDTH) / 2;
    y = _cursor.frame.origin.y + _cursor.frame.size.height + PADDING;
    w = START_AREA_WIDTH;
    h = START_AREA_HEIGHT;
    UIView* startArea = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    [self addSubview:startArea];

    x = START_AREA_WIDTH - START_WIDTH;
    y = START_AREA_HEIGHT - START_HEIGHT;
    w = START_WIDTH;
    h = START_HEIGHT;
    _start = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
    [_start setBackgroundImage:[UIImage imageNamed:@"button_start_off.png"] forState:UIControlStateNormal];
    [_start setBackgroundImage:[UIImage imageNamed:@"button_start_on.png"] forState:UIControlStateHighlighted];
    [_start addTarget:self action:@selector(touchDownStart) forControlEvents:UIControlEventTouchDown];
    [_start addTarget:self action:@selector(touchUpStart) forControlEvents:UIControlEventTouchUpInside];
    [_start addTarget:self action:@selector(touchUpStart) forControlEvents:UIControlEventTouchUpOutside];
    [_start addTarget:self action:@selector(touchUpStart) forControlEvents:UIControlEventTouchCancel];
    [startArea addSubview:_start];

    x = 0;
    y = START_AREA_HEIGHT - START_HEIGHT;
    w = START_WIDTH;
    h = START_HEIGHT;
    _select = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
    [_select setBackgroundImage:[UIImage imageNamed:@"button_select_off.png"] forState:UIControlStateNormal];
    [_select setBackgroundImage:[UIImage imageNamed:@"button_select_on.png"] forState:UIControlStateHighlighted];
    [_select addTarget:self action:@selector(touchDownSelect) forControlEvents:UIControlEventTouchDown];
    [_select addTarget:self action:@selector(touchUpSelect) forControlEvents:UIControlEventTouchUpInside];
    [_select addTarget:self action:@selector(touchUpSelect) forControlEvents:UIControlEventTouchUpOutside];
    [_select addTarget:self action:@selector(touchUpSelect) forControlEvents:UIControlEventTouchCancel];
    [startArea addSubview:_select];
}

-(void)setPadStatus {
    int s = 0;
    s |= _padStatus.a ? 1 : 0;
    s |= _padStatus.b ? 2 : 0;
    s |= _padStatus.select ? 4 : 0;
    s |= _padStatus.start ? 8 : 0;
    s |= _padStatus.up ? 16 : 0;
    s |= _padStatus.down ? 32 : 0;
    s |= _padStatus.left ? 64 : 0;
    s |= _padStatus.right ? 128 : 0;
    int p = PAD_STATUS;
    if ((p & 1) && !(s & 1)) {
        [_a setImage:_aOff];
    } else if (!(p & 1) && (s & 1)) {
        [_a setImage:_aOn];
    }
    if ((p & 2) && !(s & 2)) {
        [_b setImage:_bOff];
    } else if (!(p & 2) && (s & 2)) {
        [_b setImage:_bOn];
    }
    if ((p & 16) && !(s & 16)) {
        [_up setImage:_upOff];
    } else if (!(p & 16) && (s & 16)) {
        [_up setImage:_upOn];
    }
    if ((p & 32) && !(s & 32)) {
        [_down setImage:_downOff];
    } else if (!(p & 32) && (s & 32)) {
        [_down setImage:_downOn];
    }
    if ((p & 64) && !(s & 64)) {
        [_left setImage:_leftOff];
    } else if (!(p & 64) && (s & 64)) {
        [_left setImage:_leftOn];
    }
    if ((p & 128) && !(s & 128)) {
        [_right setImage:_rightOff];
    } else if (!(p & 128) && (s & 128)) {
        [_right setImage:_rightOn];
    }
    PAD_STATUS = s;
}

-(void)touchDownStart {
    _padStatus.start = YES;
    [self setPadStatus];
}

-(void)touchUpStart {
    _padStatus.start = NO;
    [self setPadStatus];
}

-(void)touchDownSelect {
    _padStatus.select = YES;
    [self setPadStatus];
}

-(void)touchUpSelect {
    _padStatus.select = NO;
    [self setPadStatus];
}

-(void)checkCursorWithOrigin:(CGPoint)origin {
    int x = origin.x - _cursor.frame.origin.x;
    int y = origin.y - _cursor.frame.origin.y;
    int cx = _cursor.frame.size.width / 2;
    int cy = _cursor.frame.size.height / 2;
    if (cx - cx / 5 < x && x < cx + cx / 5 && cy - cy / 5 < y && y < cy + cy / 5) {
        _padStatus.up = NO;
        _padStatus.down = NO;
        _padStatus.left = NO;
        _padStatus.right = NO;
    } else {
        float r = atan2f(x - cx, y - cy) + M_PI / 2;
        while (M_PI * 2 <= r) r -= M_PI * 2;
        while (r < 0) r += M_PI * 2;
        _padStatus.down = 0.5235987755983 <= r && r <= 2.6179938779915;
        _padStatus.right = 2.2689280275926 <= r && r <= 4.1887902047864;
        _padStatus.up = 3.6651914291881 <= r && r <= 5.7595865315813;
        _padStatus.left = r <= 1.0471975511966 || 5.235987755983 <= r;
    }
    [self setPadStatus];
}

-(void)checkButtonWithOrigin:(CGPoint)origin {
    int x = origin.x - _buttonTouchArea.frame.origin.x;
    int y = origin.y - _buttonTouchArea.frame.origin.y;
    if (x < 0 || BUTTON_SIZE < x || y < 0 || BUTTON_SIZE * 2 + PADDING < y) {
        _padStatus.a = NO;
        _padStatus.b = NO;
    } else {
        if (BUTTON_SIZE + PADDING + 10 < y) {
            _padStatus.a = NO;
            _padStatus.b = YES;
        } else if (y < BUTTON_SIZE - 10) {
            _padStatus.a = YES;
            _padStatus.b = NO;
        } else {
            _padStatus.a = YES;
            _padStatus.b = YES;
        }
    }
    [self setPadStatus];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self checkTouches:touches event:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self checkTouches:touches event:event];
}

-(void)checkTouches:(NSSet*)touches event:(UIEvent*)event {
    for (UITouch* touch in touches) {
        if (touch.view.tag == TAG_PAD_AREA) {
            [self checkCursorWithOrigin:[touch locationInView:self]];
        } else if (touch.view.tag == TAG_BUTTON_AREA) {
            [self checkButtonWithOrigin:[touch locationInView:self]];
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch* touch in touches) {
        if (touch.view.tag == TAG_PAD_AREA) {
            _padStatus.up = NO;
            _padStatus.down = NO;
            _padStatus.left = NO;
            _padStatus.right = NO;
            [self setPadStatus];
        } else if (touch.view.tag == TAG_BUTTON_AREA) {
            _padStatus.a = NO;
            _padStatus.b = NO;
            [self setPadStatus];
        }
    }
}

@end
