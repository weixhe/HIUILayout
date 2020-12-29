//
//  UIView+HIUILayoutManager.m
//  HIUILayout
//
//  Created by weixhe on 2020/12/16.
//

#import "UIView+HIUILayoutManager.h"
#import <objc/runtime.h>
#import "HIUILayoutManager_Private.h"

@implementation UIView (HIUILayoutManager)

- (HIUILayoutManager *)layoutM {
    HIUILayoutManager *layoutM = objc_getAssociatedObject(self, _cmd);
    if (!layoutM) {
        layoutM = [[HIUILayoutManager alloc] initWithView:self];
        objc_setAssociatedObject(self, _cmd, layoutM, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layoutM;
}

- (void)configureLayoutWithBlock:(void (^)(HIUILayoutManager * _Nonnull))block {
    if (block != nil) {
        block(self.layoutM);
        [self.layoutM applyLayoutPreservingOrigin:NO];
    }
}

@end

