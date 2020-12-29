//
//  UIView+HIUILayoutManager.h
//  HIUILayout
//
//  Created by weixhe on 2020/12/16.
//

#import <UIKit/UIKit.h>
#import "HIUILayoutManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (HIUILayoutManager)

@property (nonatomic, strong, readonly) HIUILayoutManager *layoutM;

/// 布局 View 的方法, 在 block 中使用 layoutManager 进行布局
- (void)configureLayoutWithBlock:(void (^)(HIUILayoutManager *layout))block;

@end



NS_ASSUME_NONNULL_END
