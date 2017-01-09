//
//  NESView.h
//
//  Created by Yoji Suzuki on 2017/01/07.
//  Copyright © 2017年 SUZUKI PLAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol NESViewDelegate <NSObject>
-(void)gameScreenDidUpdate;
@end

@interface NESView : UIView
@property (readwrite) id<NESViewDelegate> delegate;
-(BOOL)loadRomWithData:(NSData*)data;
@end
