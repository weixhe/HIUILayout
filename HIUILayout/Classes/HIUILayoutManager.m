//
//  HIUILayoutManager.m
//  HIUILayout
//
//  Created by weixhe on 2020/12/16.
//

#import "HIUILayoutManager.h"
#import "HIUILayoutManager_Private.h"
#import "UIView+HIUILayoutManager.h"

typedef NS_ENUM(NSUInteger, HIUIViewStyle) {
    HIUIViewStyleDefault,
    HIUIViewStyleImageView,
    HIUIViewStyleLabel,
    HIUIViewStyleButton,
};

@interface HIUILayoutManager ()

@property (nonatomic, weak, readonly) UIView *view;
@property (nonatomic, strong) NSArray <HIUILayoutManager *> *childNodes;
@property (nonatomic, strong) NSArray <HIUILayoutManager *> *splitNodes;
@property (nonatomic, weak) HIUILayoutManager *parentNode;
@property (nonatomic, assign) HIUIViewStyle style;      // 视图的类型[ImageView, Label, Button]
@property (nonatomic, assign) CGFloat computeFlexGrow;  // 计算扩张
@property (nonatomic, assign) CGFloat computeFlexShrik; // 计算收缩
@property (nonatomic, assign) CGFloat surplus;          // 剩余的空间，用于 flexGrow 属性下子视图拉伸

@end

@implementation HIUILayoutManager

/// 初始化
- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        _view = view;
        _isEnabled = YES;
        _isIncludedInLayout = YES;
        _flexDirection = HIUIFlexDirectionHorizontal;
//        _flexGrow = 1;
        _computeFlexGrow = 0;
        _computeFlexShrik = 0;
        _surplus = 0;
        _fitSizeSelf = YES;
        if ([view isKindOfClass:[UILabel class]]) {
            _style = HIUIViewStyleLabel;
        } else if ([view isKindOfClass:[UIImageView class]]) {
            _style = HIUIViewStyleImageView;
        } else if ([view isKindOfClass:[UIButton class]]){
            _style = HIUIViewStyleButton;
        } else {
            _style = HIUIViewStyleDefault;
        }
    }
    return self;
}

- (void)applyLayoutPreservingOrigin:(BOOL)preserveOrigin {
//    NSAssert(self.view.superview != nil, @"HIUILayoutManager 请先添加视图到父视图上");
    NSAssert([NSThread isMainThread], @"HIUILayoutManager 布局只能在主线程中进行");
    NSAssert(self.isEnabled, @"当前视图被禁止使用 HIUILayoutManager 进行布局");
    [self prepareToCalculateLayout];
    [self calculateLayoutSizeWithNode:self]; // 计算视图的 Size
    [self calculateLayoutFrameWithNode:self]; // 计算视图的 Frame
    [self didFinishedCalculate:preserveOrigin];
}

/// 计算开始之前的准备工作，遍历查找所有的子视图
- (void)prepareToCalculateLayout {
    HIUIAttachNodesFromViewHierachy(self.view);
}

/// 计算过程结束，开始设置view的frame
- (void)didFinishedCalculate:(BOOL)preserveOrigin {
    HIUIApplyLayoutToViewHierarchy(self.view, preserveOrigin);
}

/// 计算当前View的布局
- (void)calculateLayoutFrameWithNode:(HIUILayoutManager *)node {
    HIUIFlexDirection flexDirection = node.flexDirection;
    HIUIFlexJustify justifyContent = node.justifyContent;
    HIUIFlexAlign flexAlign = node.alignItems;
    HIUILayoutManager *previousNode = nil;
    HIUILayoutManager *prevousMaxNode = nil;
    CGFloat surplus = 0;
    if (node.flexWrap == HIUIFlexWrapWrap) { // 允许折行
        HIUILayoutManager *copyNode = [node copy];
        for (NSArray *childArray in node.splitNodes) {
            copyNode.childNodes = childArray;
            previousNode = nil;
            HIUILayoutManager *maxNode = nil;
            CGFloat margain = [self getMarginWithNode:copyNode];
            if (flexDirection == HIUIFlexDirectionHorizontal) {
                surplus = node.height - [self getChildNodesHeight:copyNode] - margain + [self getVerticalMargin:copyNode];
                maxNode = [self getChildNodesMaxHeight:copyNode];
            } else {
                surplus = node.width - [self getChildNodesWidth:copyNode] - margain + [self getHorizontalMargin:copyNode];
                maxNode = [self getChildNodesMaxWidth:copyNode];
            }
            for (HIUILayoutManager *childNode in copyNode.childNodes) {
                CGFloat left = [self computerLeftValueWithNode:childNode previousNode:previousNode maxNode:maxNode previousMaxNode:prevousMaxNode parentNode:node flexDirection:flexDirection justifyContent:justifyContent surplus:surplus];
                CGFloat top = [self computerTopValueWithNode:childNode previousNode:previousNode maxNode:maxNode previousMaxNode:prevousMaxNode parentNode:node flexDirection:flexDirection justifyContent:justifyContent surplus:surplus];
                childNode.left = left;
                childNode.top = top;
                previousNode = childNode;
            }
            prevousMaxNode  = maxNode;
            if (flexDirection == HIUIFlexDirectionHorizontal) {
                surplus = (flexAlign == HIUIFlexAlignEnd)?(node.height - [self getChildNodesHeight:copyNode] - margain + [self getVerticalMargin:copyNode]):0;
            } else {
                surplus = (flexAlign == HIUIFlexAlignEnd)?(node.width - [self getChildNodesWidth:copyNode] - margain + [self getHorizontalMargin:copyNode]):0;
            }
            [self fitAlignItems:copyNode flexDirection:flexDirection flexAlign:flexAlign surplusValue:surplus wrap:YES];
            [self fitJustifyContentAround:copyNode flexDirection:flexDirection justifyContent:justifyContent];
        }
    } else { // 不允许折行
        CGFloat margain = [self getMarginWithNode:node];
        if (flexDirection == HIUIFlexDirectionVertical) {
            surplus = node.height - [self getChildNodesHeight:node] - margain + [self getVerticalMargin:node];
        } else {
            surplus = node.width - [self getChildNodesWidth:node] - margain + [self getHorizontalMargin:node];
        }
        for (HIUILayoutManager *childNode in node.childNodes) {
            if (node.computeFlexShrik > 0 && surplus < 0) {
                childNode.width += (flexDirection == HIUIFlexDirectionHorizontal)?(surplus * childNode.flexShrik / node.computeFlexShrik):0;
                childNode.height += (flexDirection == HIUIFlexDirectionVertical)?(surplus * childNode.flexShrik / node.computeFlexShrik):0;
            }
            if (childNode.flexShrik > 0) {
                CGFloat surplusTemp = (flexDirection == HIUIFlexDirectionVertical)?(node.width - childNode.width - (node.paddingLeft + node.marginLeft) - (node.paddingRight + childNode.marginRight)):(node.height - childNode.height - (node.paddingTop + node.marginTop) - (node.paddingBottom + childNode.marginBottom));
                if (surplusTemp < 0) {
                    childNode.width += (flexDirection == HIUIFlexDirectionVertical)?surplusTemp:0;
                    childNode.height += (flexDirection == HIUIFlexDirectionHorizontal)?surplusTemp:0;
                }
            }
            CGFloat left = [self computerLeftValueWithNode:childNode previousNode:previousNode maxNode:nil previousMaxNode:nil parentNode:node flexDirection:flexDirection justifyContent:justifyContent surplus:surplus];
            CGFloat top = [self computerTopValueWithNode:childNode previousNode:previousNode maxNode:nil previousMaxNode:nil parentNode:node flexDirection:flexDirection justifyContent:justifyContent surplus:surplus];
            childNode.left  = left;
            childNode.top = top;
            previousNode = childNode;
        }
        if (flexDirection == HIUIFlexDirectionHorizontal) {
            surplus = (flexAlign == HIUIFlexAlignEnd)?(node.height - [self getChildNodesHeight:node] - margain + [self getVerticalMargin:node]):0;
        } else {
            surplus = (flexAlign == HIUIFlexAlignEnd)?(node.width - [self getChildNodesWidth:node] - margain + [self getHorizontalMargin:node]):0;
        }
        [self fitAlignItems:node flexDirection:flexDirection flexAlign:flexAlign surplusValue:surplus wrap:NO];
        [self fitJustifyContentAround:node flexDirection:flexDirection justifyContent:justifyContent];
    }
    for (HIUILayoutManager *childNode in node.childNodes) {
        [self calculateLayoutFrameWithNode:childNode];
    }
}

/// 计算视图的Size
- (void)calculateLayoutSizeWithNode:(HIUILayoutManager *)node {
    if (node.flexWrap == HIUIFlexWrapWrap) {
        [self calculateLayoutSizeWithWarp:node];
    } else {
        [self calculateLayoutSizeWithNOWarp:node];
    }
    for (HIUILayoutManager *childNode in node.childNodes) {
        [self calculateLayoutSizeWithNode:childNode];
    }
}

/// 计算视图的Size: 允许折行
- (void)calculateLayoutSizeWithWarp:(HIUILayoutManager *)node {
    CGFloat computeHeight = 0;
    CGFloat computeWidth = 0;
    CGFloat paddingVertical = node.paddingTop + node.paddingBottom;
    CGFloat paddingHorizontal = node.paddingLeft + node.paddingRight;
    HIUIFlexDirection flexDirection = node.flexDirection;
    HIUILayoutManager *previousNode = nil;
    NSUInteger totalCount = node.childNodes.count;
    NSUInteger flexCount = node.flexCount;;
    NSMutableArray *splitArray = [NSMutableArray arrayWithCapacity:totalCount];
    NSUInteger splitIndex = 0;
    if (flexCount > 0) { // 如果已经设定了每行的个数，则按照固定个数布局
        // 计算行数
        NSUInteger row = totalCount / flexCount;
        if (totalCount % flexCount) {
            row += 1;
        }
        for (NSUInteger i = 0; i < row; i ++) { // 遍历每行，进行布局
            // 计算：如果到了第i行，子视图总数大于totalCount，说明在剩余需要布局的子视图无法充满正行，重新计算当前行的需要布局的数量
            NSUInteger childCount = (i + 1) * flexCount;
            NSUInteger contentCount = flexCount;
            if (childCount > totalCount) {
                contentCount -= (childCount - totalCount);
            }
            NSArray *childArray = [node.childNodes subarrayWithRange:NSMakeRange(i * flexCount, contentCount)];
            NSUInteger childArrayCount = childArray.count;
            [splitArray addObject:childArray];
            for (NSUInteger i = 0; i < childArrayCount; i ++) { // 遍历每列，进行布局
                HIUILayoutManager *childNode = childArray[i];
                CGSize childSize = [self calculateLeafNodeSize:childNode];
                if (childSize.width < 0 || childSize.height < 0) {
                    childNode.width = childSize.width;
                    childNode.height = childSize.height;
                    [self calculateLayoutSizeWithNode:childNode];
                    childSize.width = childNode.width;
                    childSize.height = childNode.height;
                } else {
                    childNode.width = childSize.width;
                    childNode.height = childSize.height;
                }
            }
        }
    } else { // 如果没有设定每行的个数，则沿着主轴方向逐个布局，如果当前行剩余空间不足，则自动折行
        if (flexDirection == HIUIFlexDirectionHorizontal) { // 主轴为水平方向
            for (NSUInteger i = 0; i < totalCount; i ++) {
                HIUILayoutManager *childNode = node.childNodes[i];
                CGSize childSize = [self calculateLeafNodeSize:childNode];
                if (childSize.width < 0 || childSize.height < 0) {
                    [self calculateLayoutSizeWithNode:childNode];
                    childSize.width = childNode.width;
                    childSize.height = childNode.height;
                } else {
                    childNode.width = childSize.width;
                    childNode.height = childSize.height;
                }
                computeWidth += childSize.width + [self getMaxMargin:childNode previousNode:previousNode flexDirection:flexDirection];
                CGFloat margin = node.width - paddingHorizontal - i * node.margin;
                if (computeWidth > margin) { // 判断是否需要折行？？？，margin到底是什么
                    // 如果行数是0或者超过了总的count，就折行重复上一行的内容
                    if (node.flexNumberOfLine == 0 || node.flexNumberOfLine > splitArray.count) {
                        NSMutableArray * childArray = [NSMutableArray array];
                        [childArray addObjectsFromArray:[node.childNodes subarrayWithRange:NSMakeRange(splitIndex, i - splitIndex)]];
                        [splitArray addObject:childArray];
                        splitIndex = i;
                        previousNode = nil;
                        computeWidth = childSize.height + [self getMaxMargin:childNode previousNode:previousNode flexDirection:flexDirection];
                    }
                }
                if (node.flexNumberOfLine > 0 && node.flexNumberOfLine == splitArray.count) {
                    childNode.isEnabled = NO;
                }
                previousNode = childNode;
            }
            if (splitIndex < totalCount) {
                if (node.flexNumberOfLine == 0 || node.flexNumberOfLine > splitArray.count) {
                    NSMutableArray * childArray = [NSMutableArray array];
                    [childArray addObjectsFromArray:[node.childNodes subarrayWithRange:NSMakeRange(splitIndex, totalCount - splitIndex)]];
                    [splitArray addObject:childArray];
                }
            }
        } else { // 主轴为垂直方向
            for (NSUInteger i = 0; i < totalCount; i ++) {
                HIUILayoutManager *childNode = node.childNodes[i];
                CGSize childSize = [self calculateLeafNodeSize:childNode];
                if (childSize.width < 0 || childSize.height < 0) {
                    [self calculateLayoutSizeWithNode:childNode];
                    childSize.width = childNode.width;
                    childSize.height = childNode.height;
                } else {
                    childNode.width = childSize.width;
                    childNode.height = childSize.height;
                }
                computeHeight += childSize.height + [self getMaxMargin:childNode previousNode:previousNode flexDirection:flexDirection];
                CGFloat margin = node.height - paddingVertical - i * node.margin;
                if (computeHeight > margin) {
                    if (node.flexNumberOfLine == 0 || node.flexNumberOfLine > splitArray.count) {
                        NSMutableArray * childArray = [NSMutableArray array];
                        [childArray addObjectsFromArray:[node.childNodes subarrayWithRange:NSMakeRange(splitIndex, i - splitIndex)]];
                        [splitArray addObject:childArray];
                        splitIndex = i;
                        previousNode = nil;
                        computeHeight = childSize.height + [self getMaxMargin:childNode previousNode:previousNode flexDirection:flexDirection];
                    }
                }
                if (node.flexNumberOfLine > 0 && node.flexNumberOfLine == splitArray.count) {
                    childNode.isEnabled = NO;
                }
                previousNode = childNode;
            }
            if (splitIndex < totalCount) {
                if (node.flexNumberOfLine == 0 || node.flexNumberOfLine > splitArray.count) {
                    
                    NSMutableArray * childArray = [NSMutableArray array];
                    [childArray addObjectsFromArray:[node.childNodes subarrayWithRange:NSMakeRange(splitIndex, totalCount - splitIndex)]];
                    [splitArray addObject:childArray];
                }
            }
        }
    }
    node.splitNodes = splitArray;
    NSUInteger splitCount = splitArray.count;
    node.surplus = 0;
    node.computeFlexGrow = 0;
    
    previousNode  = nil;
    computeWidth  = 0;
    computeHeight = 0;
    if (node.width < 0) {
        HIUILayoutManager *copyNode = [node copy];
        for (NSArray *childArray in node.splitNodes) {
            copyNode.childNodes = childArray;
            HIUILayoutManager *maxNode = [self getChildNodesMaxWidth:copyNode];
            computeWidth += maxNode.width + [self getMaxMargin:maxNode previousNode:previousNode flexDirection:HIUIFlexDirectionHorizontal];
            previousNode = maxNode;
        }
        node.width = computeWidth + ((splitCount == 0)?0:((splitCount - 1) * node.margin + paddingHorizontal));
    }
    if (node.height < 0) {
        HIUILayoutManager *copyNode = [node copy];
        for (NSArray *childArray in node.splitNodes) {
            copyNode.childNodes = childArray;
            HIUILayoutManager *maxNode = [self getChildNodesMaxWidth:copyNode];
            computeHeight += maxNode.height + [self getMaxMargin:maxNode previousNode:previousNode flexDirection:HIUIFlexDirectionVertical];
            previousNode = maxNode;
        }
        node.height = computeHeight + ((splitCount == 0)?0:((splitCount - 1) * node.margin + paddingVertical));
    }
}

/// 计算视图的Size: 不允许折行
- (void)calculateLayoutSizeWithNOWarp:(HIUILayoutManager *)node {
    CGFloat computeHeight = 0;
    CGFloat computeWidth = 0;
    HIUIFlexDirection flexDirection = node.flexDirection;
    CGFloat margin = [self getMarginWithNode:node];
    NSUInteger totalCount = node.childNodes.count;
    HIUILayoutManager *previousNode = nil;
    for (NSUInteger i = 0; i < totalCount; i++) {
        HIUILayoutManager *childNode = node.childNodes[i];
        CGSize childSize = [self calculateLeafNodeSize:childNode];
        if (childSize.width < 0 || childSize.height < 0) {
            childNode.width = childSize.width;
            childNode.height = childSize.height;
            [self calculateLayoutSizeWithNode:childNode];
            childSize.width = childNode.width;
            childSize.height = childNode.height;
        } else {
            childNode.width = childSize.width;
            childNode.height = childSize.height;
        }
        if (flexDirection == HIUIFlexDirectionVertical) {
            if (childSize.width > computeWidth) {
                computeWidth = childSize.width;
            }
            computeHeight += childSize.height;
        } else {
            if (childSize.height > computeHeight) {
                computeHeight = childSize.height;
            }
            computeWidth += childSize.width;
        }
        
        previousNode = childNode;
    }
    if (node.height < 0) {
        node.height = computeHeight + ((flexDirection == HIUIFlexDirectionHorizontal)?(node.paddingTop + node.paddingBottom + previousNode.marginTop + previousNode.marginBottom):margin);
    }
    if (node.width < 0) {
        node.width = computeWidth + ((flexDirection == HIUIFlexDirectionVertical)?(node.paddingLeft + node.paddingRight + previousNode.marginLeft + previousNode.marginRight):margin);
    }
}

/// 计算当前视图的Size
- (CGSize)calculateLeafNodeSize:(HIUILayoutManager *)leafNode {
    
    CGSize nodeSize = CGSizeZero;
    nodeSize.width  = leafNode.width;
    nodeSize.height = leafNode.height;
    
    if (nodeSize.width > 0 && nodeSize.height == 0) {
        nodeSize.height = (leafNode.aspectRatio == 0) ? nodeSize.height : (nodeSize.width / leafNode.aspectRatio);
    }
    if (nodeSize.height > 0 && nodeSize.width == 0) {
        nodeSize.width = (leafNode.aspectRatio == 0) ? nodeSize.width : (nodeSize.height * leafNode.aspectRatio);
    }
    if (nodeSize.width > 0 && nodeSize.height > 0) {
        return nodeSize;
    }
    if (leafNode.style == HIUIViewStyleLabel && leafNode.fitSizeSelf == NO) { // 单独处理label自动布局 ？？？fitSizeSelf == YES
        CGSize fitSize = [leafNode.view sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
        nodeSize.width = fitSize.width;
        nodeSize.height = fitSize.height;
    }
    if (nodeSize.width > 0 && nodeSize.height > 0) {
        return nodeSize;
    }
    HIUILayoutManager *parentNode = leafNode.parentNode;
    if (nodeSize.width == 0) {
        if (parentNode.width > 0) {
            CGFloat value = [self fitFlexGrowWithNode:leafNode parentNode:parentNode flexDirection:parentNode.flexDirection];
            if (parentNode.flexDirection == HIUIFlexDirectionVertical) {
                nodeSize.height += value;
            } else {
                nodeSize.width += value;
            }
            if (nodeSize.width == 0) {
                if (parentNode.childNodes.count == 1 || (parentNode.flexDirection == HIUIFlexDirectionVertical && parentNode.flexWrap != HIUIFlexWrapWrap)) {
                    if (parentNode.paddingLeft >= 0 && parentNode.paddingRight >= 0) {
                        nodeSize.width = parentNode.width - parentNode.paddingLeft - parentNode.paddingRight - leafNode.marginLeft - leafNode.marginRight;
                    }
                }
            }
            
            if (leafNode.aspectRatio > 0 && nodeSize.width > 0) {
                nodeSize.height = nodeSize.width / leafNode.aspectRatio;
            }
        }
    }
    if (nodeSize.height == 0) {
        if (parentNode.height > 0) {
            CGFloat value = [self fitFlexGrowWithNode:leafNode parentNode:parentNode flexDirection:parentNode.flexDirection];
            if (parentNode.flexDirection == HIUIFlexDirectionVertical) {
                nodeSize.height += value;
            } else {
                nodeSize.width += value;
            }
            if (nodeSize.height == 0) {
                if (parentNode.childNodes.count == 1 || (parentNode.flexDirection == HIUIFlexDirectionHorizontal && parentNode.flexWrap != HIUIFlexWrapWrap)) {
                    if (parentNode.paddingTop >= 0 && parentNode.paddingBottom >= 0) {
                        nodeSize.height = parentNode.height - parentNode.paddingTop - parentNode.paddingBottom - leafNode.marginTop - leafNode.marginBottom;
                    }
                }
            }
            if (leafNode.aspectRatio > 0 && nodeSize.height > 0) {
                nodeSize.width = nodeSize.height * leafNode.aspectRatio;
            }
        }
    }
    if (nodeSize.width > 0 && nodeSize.height > 0) {
        return nodeSize;
    }
    if (leafNode.style == HIUIViewStyleImageView) {
        UIImageView *imageView = (UIImageView *)leafNode.view;
        UIImage *image = imageView.image;
        if (leafNode.fitSizeSelf == NO) {
            if (image != nil && nodeSize.width == 0) {
                nodeSize.width = image.size.width;
            }
            if (image != nil && nodeSize.height == 0) {
                nodeSize.height = image.size.height;
            }
        } else {
            nodeSize.width =  (image != nil)?image.size.width:nodeSize.width;
            nodeSize.height = (image != nil)?image.size.height:nodeSize.height;
        }
        return nodeSize;
    }
    if (nodeSize.width <= 0) {
        nodeSize.width = (leafNode.style == HIUIViewStyleDefault)?nodeSize.width:0;
    }
    if (nodeSize.height <= 0) {
        nodeSize.height = (leafNode.style == HIUIViewStyleDefault)?nodeSize.height:0;
    }
    if (nodeSize.width < 0 || nodeSize.height < 0) {
        return nodeSize;
    }
    CGSize fitSize = [leafNode.view sizeThatFits:nodeSize];
    if (nodeSize.width > 0 && nodeSize.width != MAXFLOAT) {
        fitSize.width = nodeSize.width;
    }
    if (nodeSize.height > 0 && nodeSize.height != MAXFLOAT) {
        fitSize.height = nodeSize.height;
    }
    return fitSize;
}

/// 计算子视图铺满父视图需要拉伸的尺寸, 并返回计算结果
- (CGFloat)fitFlexGrowWithNode:(HIUILayoutManager *)node parentNode:(HIUILayoutManager *)parentNode flexDirection:(HIUIFlexDirection)flexDirection {
    CGFloat value = 0;
    if (parentNode.computeFlexGrow > 0) { // 子视图允许拉伸，如果父视图的空间有富余，那么子视图将根据各自的拉伸系数进行拉伸
        if (flexDirection == HIUIFlexDirectionVertical) {
            CGFloat surplusHeight = parentNode.surplus;
            if (surplusHeight == 0) { // 没有计算剩余空间，需要先计算父视图的剩余空间
                CGFloat margin = [self getMarginWithNode:parentNode];
                CGFloat height = [self getChildNodesHeight:parentNode];
                surplusHeight = parentNode.height - margin - height;
                parentNode.surplus = surplusHeight;
            }
            if (surplusHeight > 0) { // 已经计算好剩余空间，按照 flexGrow 比例计算 node 需要拉伸的值
                value = surplusHeight * node.flexGrow / parentNode.computeFlexGrow;
                node.flexGrow = 0;
            }
            
        } else {
            CGFloat surplusWidth = parentNode.surplus;
            if (surplusWidth == 0) {
                CGFloat margain = [self getMarginWithNode:parentNode];
                CGFloat width = [self getChildNodesWidth:parentNode];
                surplusWidth = parentNode.width - margain - width;
                parentNode.surplus = surplusWidth;
            }
            if (surplusWidth > 0) {
                value = surplusWidth * node.flexGrow / parentNode.computeFlexGrow;
                node.flexGrow = 0;
            }
        }
    } else { // 子视图不拉伸，
        if (parentNode.flexCount > 0) {
            if (flexDirection == HIUIFlexDirectionVertical) {
                
                if (parentNode.surplus == 0) { // 父视图没有多余空间的情况下
                    HIUILayoutManager *copyNode = [parentNode copy];
                    if (parentNode.childNodes.count >= parentNode.flexCount) { // 子视图总数 >= 需要布局的子视图数量
                        NSArray *childArray = [node.childNodes subarrayWithRange:NSMakeRange(0, parentNode.flexCount)];
                        copyNode.childNodes = childArray;
                    } else { // 子视图总数 < 需要布局的子视图数量，这个时候多余的数量，需要创建temp填充
                        NSMutableArray *mArray = [NSMutableArray arrayWithArray:parentNode.childNodes];
                        NSUInteger count = parentNode.flexCount - parentNode.childNodes.count;
                        for (NSUInteger i = 0; i < count; i++) {
                            HIUILayoutManager *tempNode = [[HIUILayoutManager alloc]init];
                            [mArray addObject:tempNode];
                        }
                    }
                    // 计算出去两头padding和margin后的间距总和 = 间距总和 - 两头的间距
                    CGFloat margin = [self getMarginWithNode:copyNode] - [self getVerticalMargin:copyNode];
                    CGFloat surplusHeight = (parentNode.height - margin) / parentNode.flexCount;
                    parentNode.surplus = surplusHeight;
                    if (surplusHeight > 0) {
                        value = surplusHeight;
                    }
                } else {
                    CGFloat surplusHeight = parentNode.surplus;
                    if (surplusHeight > 0) {
                        value = surplusHeight;
                    }
                }
            } else {
                if (parentNode.surplus == 0) {
                    HIUILayoutManager *copyNode = [parentNode copy];
                    if (parentNode.childNodes.count >= parentNode.flexCount) {
                        NSArray *childArray = [parentNode.childNodes subarrayWithRange:NSMakeRange(0, parentNode.flexCount)];
                        copyNode.childNodes = childArray;
                    } else {
                        NSMutableArray *mArray = [NSMutableArray arrayWithArray:parentNode.childNodes];
                        NSUInteger count = parentNode.flexCount - parentNode.childNodes.count;
                        for (NSUInteger i = 0; i < count; i++) {
                            HIUILayoutManager *tempNode = [[HIUILayoutManager alloc]init];
                            [mArray addObject:tempNode];
                        }
                        copyNode.childNodes = mArray;
                    }
                    CGFloat margain = [self getMarginWithNode:copyNode] - [self getVerticalMargin:copyNode];
                    CGFloat surplusWidth = (parentNode.width - margain) / parentNode.flexCount;
                    parentNode.surplus = surplusWidth;
                    if (surplusWidth > 0) {
                        value = surplusWidth;
                    }
                } else {
                    CGFloat surplusWidth = parentNode.surplus;
                    if (surplusWidth > 0) {
                        value = surplusWidth;
                    }
                }
            }
        }
    }
    return value;
}

/// 获取交叉轴上子视图的宽度
- (CGFloat)getAlignItemsWidthWithWrap:(HIUILayoutManager *)node flexDirection:(HIUIFlexDirection)flexDirection flexAlign:(HIUIFlexAlign)flexAlign {
    if (flexAlign == HIUIFlexAlignDefault) {
        return 0;
    }
    CGFloat width = 0;
    CGFloat height = 0;
    HIUILayoutManager *previousMaxNode = nil;
    for (NSArray *childArray in node.splitNodes) {
        HIUILayoutManager *copyNode = [node copy];
        copyNode.childNodes = childArray;
        HIUILayoutManager *maxNode = (flexDirection == HIUIFlexDirectionVertical)?[self getChildNodesMaxWidth:copyNode]:[self getChildNodesMaxHeight:node];
        CGFloat margin = 0;
        if (flexDirection == HIUIFlexDirectionVertical) {
            margin = [self getMaxMargin:maxNode previousNode:previousMaxNode flexDirection:HIUIFlexDirectionHorizontal];
        } else {
            margin = [self getMaxMargin:maxNode previousNode:previousMaxNode flexDirection:HIUIFlexDirectionVertical];
        }
        width += margin + maxNode.width - ((previousMaxNode != nil)?0:(maxNode.marginLeft));
        height += margin + maxNode.height - ((previousMaxNode != nil)?0:(maxNode.marginTop));
    }
    CGFloat surplus = 0;
    if (flexDirection == HIUIFlexDirectionVertical) {
        surplus = node.width - width;
    } else {
        surplus = node.height - height;
    }
    return surplus;
}

- (void)fitAlignItems:(HIUILayoutManager *)node flexDirection:(HIUIFlexDirection)flexDirection flexAlign:(HIUIFlexAlign)flexAlign surplusValue:(CGFloat)surplusValue wrap:(BOOL)wrap {
    if (flexAlign == HIUIFlexAlignDefault) {
        return ;
    }
    HIUILayoutManager *tempNode = nil;
    switch (flexAlign) {
        case HIUIFlexAlignStart:
            tempNode = (flexDirection == HIUIFlexDirectionVertical)?[self getChildNodesMinWidth:node]:[self getChildNodesMinHeight:node];
            break;
        case HIUIFlexAlignCenter:
            tempNode = (flexDirection == HIUIFlexDirectionVertical)?[self getChildNodesMaxWidth:node]:[self getChildNodesMaxHeight:node];
            break;
        default:
            break;
    }
    CGFloat surplus = 0;
    for (HIUILayoutManager *childNode in node.childNodes) {
        switch (flexAlign) {
            case HIUIFlexAlignStart:
                childNode.left = (flexDirection == HIUIFlexDirectionVertical)?tempNode.left:childNode.left;
                childNode.top = (flexDirection == HIUIFlexDirectionHorizontal)?tempNode.top:childNode.top;
                break;
            case HIUIFlexAlignEnd: {
                childNode.left = (flexDirection == HIUIFlexDirectionVertical)?(surplusValue - childNode.marginRight - node.parentNode.paddingRight + childNode.left):childNode.left;
                childNode.top = (flexDirection == HIUIFlexDirectionHorizontal)?(surplusValue - childNode.marginBottom - node.parentNode.paddingBottom + childNode.top):childNode.top;
            }
                break;
            case HIUIFlexAlignCenter: {
                if (wrap == YES) {
                    childNode.left = (flexDirection == HIUIFlexDirectionVertical)?(tempNode.left - (tempNode.width - childNode.width )/ 2.):childNode.left;
                    childNode.top = (flexDirection == HIUIFlexDirectionHorizontal)?(tempNode.top - (tempNode.height - childNode.height )/ 2.):childNode.top;
                } else {
                    surplus = (flexDirection == HIUIFlexDirectionVertical)?(node.width - childNode.width):(node.height - childNode.height);
                    childNode.left = (flexDirection == HIUIFlexDirectionVertical)?(surplus / 2.):childNode.left;
                    childNode.top = (flexDirection == HIUIFlexDirectionHorizontal)?(surplus / 2.):childNode.top;
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)fitJustifyContentAround:(HIUILayoutManager *)parentNode flexDirection:(HIUIFlexDirection)flexDirection justifyContent:(HIUIFlexJustify)justifyContent {
    if (justifyContent == HIUIFlexJustifyStartAround) {
        HIUILayoutManager *node = parentNode.childNodes.lastObject;
        node.left = (flexDirection == HIUIFlexDirectionHorizontal)?(parentNode.width - node.width - parentNode.paddingRight - node.marginRight):node.left;
        node.top = (flexDirection == HIUIFlexDirectionVertical)?(parentNode.height - node.height - parentNode.paddingBottom - node.marginBottom):node.top;
    }
    if (justifyContent == HIUIFlexJustifyEndAround) {
        HIUILayoutManager *node = parentNode.childNodes.firstObject;
        node.left = (flexDirection == HIUIFlexDirectionHorizontal)?(parentNode.paddingLeft + node.marginLeft):node.left;
        node.top = (flexDirection == HIUIFlexDirectionVertical)?(parentNode.paddingTop + node.marginTop):node.top;
    }
}

/// 计算 left 值
- (CGFloat)computerLeftValueWithNode:(HIUILayoutManager *)node
                        previousNode:(HIUILayoutManager *)previousNode
                             maxNode:(HIUILayoutManager *)maxNode
                     previousMaxNode:(HIUILayoutManager *)previousMaxNode
                          parentNode:(HIUILayoutManager *)parentNode
                       flexDirection:(HIUIFlexDirection)flexDirection
                      justifyContent:(HIUIFlexJustify)justifyContent
                             surplus:(CGFloat)surplus
{
    CGFloat left = 0;
    CGFloat margin = 0;
    if (parentNode.flexWrap == HIUIFlexWrapWrap && flexDirection == HIUIFlexDirectionVertical) {
        margin = [self getMaxMargin:maxNode previousNode:previousMaxNode flexDirection:HIUIFlexDirectionHorizontal];
    } else {
        margin = (flexDirection == HIUIFlexDirectionHorizontal)?([self getMaxMargin:node previousNode:previousNode flexDirection:flexDirection]):0;
    }
    if (parentNode.flexWrap == HIUIFlexWrapWrap && flexDirection == HIUIFlexDirectionVertical) {
        left = (previousMaxNode != nil)?(previousMaxNode.left + margin + previousMaxNode.width + parentNode.margin):(parentNode.paddingLeft + margin);
    } else {
        if (flexDirection == HIUIFlexDirectionHorizontal) {
            left = (previousNode != nil)?(previousNode.left + margin + previousNode.width + parentNode.margin):(parentNode.paddingLeft + margin);
        } else {
            left = parentNode.paddingLeft + margin + node.marginLeft;
        }
    }
    if (flexDirection == HIUIFlexDirectionHorizontal) {
        switch (justifyContent) {
            case HIUIFlexJustifyStart:
            case HIUIFlexJustifyStartAround:
                left = left;
                break;
            case HIUIFlexJustifyEnd:
            case HIUIFlexJustifyEndAround:
                left = (previousNode != nil)?left:(surplus - parentNode.paddingRight - node.marginRight);
                break;
            case HIUIFlexJustifyCenter:
                left = (previousNode != nil)?left:surplus/2.;
            default:
                break;
        }
    }
    return left;
}

/// 计算 top 值
- (CGFloat)computerTopValueWithNode:(HIUILayoutManager *)node
                       previousNode:(HIUILayoutManager *)previousNode
                            maxNode:(HIUILayoutManager *)maxNode
                    previousMaxNode:(HIUILayoutManager *)previousMaxNode
                         parentNode:(HIUILayoutManager *)parentNode
                      flexDirection:(HIUIFlexDirection)flexDirection
                     justifyContent:(HIUIFlexJustify)justifyContent
                            surplus:(CGFloat)surplus
{
    CGFloat top = 0;
    CGFloat margin = 0;
    if (parentNode.flexWrap == HIUIFlexWrapWrap && flexDirection == HIUIFlexDirectionHorizontal) {
        margin = [self getMaxMargin:maxNode previousNode:previousMaxNode flexDirection:HIUIFlexDirectionVertical];
    } else {
        margin = (flexDirection == HIUIFlexDirectionVertical) ? ([self getMaxMargin:node previousNode:previousNode flexDirection:flexDirection]) : 0;
    }
    if (parentNode.flexWrap == HIUIFlexWrapWrap && flexDirection == HIUIFlexDirectionHorizontal) {
        top = (previousMaxNode != nil)?(previousMaxNode.top + margin + previousMaxNode.height + parentNode.margin):(parentNode.paddingTop + margin);
    } else {
        if (flexDirection == HIUIFlexDirectionVertical) {
            top = (previousNode != nil)?(previousNode.top + margin + previousNode.height + parentNode.margin):(parentNode.paddingTop + margin);
        } else {
            top = parentNode.paddingTop + margin + node.marginTop;
        }
    }
    if (flexDirection == HIUIFlexDirectionVertical) {
        
        switch (justifyContent) {
            case HIUIFlexJustifyStart:
            case HIUIFlexJustifyStartAround:
                top = top;
                break;
            case HIUIFlexJustifyEnd:
            case HIUIFlexJustifyEndAround:
                top = (previousNode != nil)?top:(surplus - parentNode.paddingBottom - parentNode.childNodes.lastObject.marginBottom);
                break;
            case HIUIFlexJustifyCenter:
                top = (previousNode != nil)?top:(top + surplus/2.);
            default:
                break;
        }
    }
    return top;
}

/// 计算水平方向的左右两边的间距，并返回结果值
- (CGFloat)getHorizontalMargin:(HIUILayoutManager *)node {
    CGFloat margin = 0;
    margin = node.childNodes.firstObject.marginLeft + node.childNodes.lastObject.marginRight;
    margin += (node.paddingLeft + node.paddingRight);
    return margin;
}

/// 计算垂直方向的上下两头的间距，并返回结果值
- (CGFloat)getVerticalMargin:(HIUILayoutManager *)node {
    CGFloat margin = 0;
    margin = node.childNodes.firstObject.marginTop + node.childNodes.lastObject.marginBottom;
    margin += (node.paddingTop + node.paddingBottom);
    return margin;
}

/// 计算当前视图中所有子视图主动设定的间距总和，并返回结果值
- (CGFloat)getMarginWithNode:(HIUILayoutManager *)node {
    CGFloat margin = 0;
    NSUInteger count = node.childNodes.count;
    if (node.flexDirection == HIUIFlexDirectionVertical) {
        margin = node.paddingTop + node.paddingBottom + ((count == 0)?0:(count - 1) * node.margin);
        HIUILayoutManager *previousNode = nil;
        for (HIUILayoutManager *childNode in node.childNodes) {
            CGFloat gap = [self getMaxMargin:childNode previousNode:previousNode flexDirection:node.flexDirection];
            margin += gap;
            previousNode = childNode;
        }
        margin += previousNode.marginBottom;
    } else {
        margin = node.paddingLeft + node.paddingRight + ((count == 0)?0:(count - 1) * node.margin);
        HIUILayoutManager *previousNode = nil;
        for (HIUILayoutManager *childNode in node.childNodes) {
            CGFloat gap = [self getMaxMargin:childNode previousNode:previousNode flexDirection:node.flexDirection];
            margin += gap;
            previousNode = childNode;
        }
        margin += previousNode.marginRight;
    }
    return margin;
}

/// 计算当前视图到前一个视图之间的最大间距, 并返回结果值
- (CGFloat)getMaxMargin:(HIUILayoutManager *)node previousNode:(HIUILayoutManager *)preiviousNode flexDirection:(HIUIFlexDirection)flexDirection {
    CGFloat margin = 0;
    if (flexDirection == HIUIFlexDirectionHorizontal) {
        if (preiviousNode == nil) {
            margin = node.marginLeft;
        } else {
            if (preiviousNode.marginRight == 0) {
                margin = node.marginLeft;
            } else if (node.marginLeft == 0) {
                margin = preiviousNode.marginRight;
            } else {
                margin = MAX(preiviousNode.marginRight, node.marginLeft);
            }
        }
    } else {
        if (preiviousNode == nil) {
            margin = node.marginTop;
        } else {
            if (preiviousNode.marginBottom == 0) {
                margin = node.marginTop;
            } else if (node.marginTop == 0) {
                margin = preiviousNode.marginBottom;
            } else {
                margin =  MAX(preiviousNode.marginBottom, node.marginTop);
            }
        }
    }
    return margin;
}

/// 获取所有子视图中高度最大的视图, 并返回对应的 layoutManager
- (HIUILayoutManager *)getChildNodesMaxHeight:(HIUILayoutManager *)node {
    HIUILayoutManager *maxNode = nil;
    CGFloat maxHeight = 0;
    for (HIUILayoutManager *childNode in node.childNodes) {
        CGFloat margin = childNode.height + childNode.marginTop + childNode.parentNode.paddingTop;
        if (maxHeight < margin) {
            maxNode = childNode;
            maxHeight = margin;
        }
    }
    return maxNode;
}

/// 获取所有子视图中宽度最大的视图, 并返回对应的 layoutManager
- (HIUILayoutManager *)getChildNodesMaxWidth:(HIUILayoutManager *)node {
    HIUILayoutManager *maxNode = nil;
    CGFloat maxWidth = 0;
    for (HIUILayoutManager *childNode in node.childNodes) {
        CGFloat margin = childNode.width + childNode.marginLeft + childNode.parentNode.paddingLeft;
        if (maxWidth < margin) {
            maxNode = childNode;
            maxWidth = margin;
        }
    }
    return maxNode;
}

/// 获取子所有子视图中高度最小的视图, 并返回对应的 layoutManager
- (HIUILayoutManager *)getChildNodesMinHeight:(HIUILayoutManager *)node {
    HIUILayoutManager *minNode = nil;
    CGFloat minHeight = MAXFLOAT;
    for (HIUILayoutManager *childNode in node.childNodes) {
        CGFloat margin = childNode.height + childNode.marginTop + childNode.parentNode.paddingTop;
        if (minHeight > margin) {
            minNode = childNode;
            minHeight = margin;
        }
    }
    return minNode;
}

/// 获取所有子视图中宽度最小的视图, 并返回对应的 layoutManager
- (HIUILayoutManager *)getChildNodesMinWidth:(HIUILayoutManager *)node {
    HIUILayoutManager *minNode = nil;
    CGFloat minWidth = 0;
    for (HIUILayoutManager *childNode in node.childNodes) {
        CGFloat margin = childNode.width + childNode.marginLeft + childNode.parentNode.paddingLeft;
        if (minWidth > margin) {
            minNode = childNode;
            minWidth = margin;
        }
    }
    return minNode;
}

/// 获取所有子视图的高度总和, 并返回
- (CGFloat)getChildNodesHeight:(HIUILayoutManager *)node {
    CGFloat maxHeight = 0;
    for (HIUILayoutManager *childNode in node.childNodes) {
        maxHeight += childNode.height;
    }
    return maxHeight;
}

/// 获取所有子视图的宽度总和, 并返回
- (CGFloat)getChildNodesWidth:(HIUILayoutManager *)node {
    CGFloat maxWidth = 0;
    for (HIUILayoutManager *childNode in node.childNodes) {
        maxWidth += childNode.width;
    }
    return maxWidth;
}

- (void)setPadding:(CGFloat)padding {
    _padding = padding;
    _paddingTop = padding;
    _paddingLeft = padding;
    _paddingRight = padding;
    _paddingBottom = padding;
}

//- (void)setLeft:(CGFloat)left {
//    if (self.right > 0) {
//        self.width =
//        self.width = (self.parentNode != nil)?(self.parentNode.width - self.parentNode.paddingLeft - self.parentNode.paddingRight - self.marginLeft - left)
//    }
//}

//- (void)setRight:(CGFloat)right {
//
//}

- (void)setHidden:(BOOL)hidden {
    _hidden = hidden;
    if (hidden == YES) {
        self.isEnabled = NO;
        self.view.hidden = YES;
    } else {
        self.isEnabled = YES;
        self.view.hidden = NO;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    HIUILayoutManager *deepCopy = [[[self class] alloc] init];
    deepCopy.paddingLeft    = self.paddingLeft;
    deepCopy.paddingRight   = self.paddingRight;
    deepCopy.paddingBottom  = self.paddingBottom;
    deepCopy.paddingTop     = self.paddingTop;
    deepCopy.margin         = self.margin;
    deepCopy.flexDirection  = self.flexDirection;
    deepCopy.width          = self.width;
    deepCopy.height         = self.height;
    return deepCopy;
}

/// 递归遍历视图 View, 找到 View 上所有的子视图
static void HIUIAttachNodesFromViewHierachy(UIView *const view) {
    HIUILayoutManager *const layout = view.layoutM;
    
    NSMutableArray<UIView *> *subviewsToInclude = [[NSMutableArray alloc] initWithCapacity:view.subviews.count];
    for (UIView *subview in view.subviews) {
        // 隐去系统的内部视图类
        if ([NSStringFromClass(subview.class) hasPrefix:@"_UI"]) {
            continue;
        }
        if (subview.layoutM.isEnabled && subview.layoutM.isIncludedInLayout) {
            [subviewsToInclude addObject:subview];
        }
    }
    layout.computeFlexGrow = 0;
    layout.computeFlexShrik = 0;
    layout.surplus = 0;
    NSMutableArray *childNodes = [NSMutableArray arrayWithCapacity:subviewsToInclude.count];
    for (UIView *const subview in subviewsToInclude) {
        subview.frame = CGRectZero;
        HIUILayoutManager *subviewLayout = subview.layoutM;
        layout.computeFlexGrow += subviewLayout.flexGrow;
        layout.computeFlexShrik += subviewLayout.flexShrik;
        subviewLayout.parentNode = layout;
        [childNodes addObject:subviewLayout];
    }
    layout.childNodes = childNodes;
    
    for (UIView *const subview in subviewsToInclude) {
        HIUIAttachNodesFromViewHierachy(subview);
    }
}

/// 在视图层级中应用布局
/// @param view 视图view
/// @param preserveOrigin 是否保留原来的坐标，即在原来的起始位置的基础上再次计算布局
static void HIUIApplyLayoutToViewHierarchy(UIView *view, BOOL preserveOrigin) {
    NSCAssert([NSThread isMainThread], @"HIUILayoutManager 布局只能在主线程中进行");
    HIUILayoutManager *layout = view.layoutM;
    if (!layout.isIncludedInLayout) {
        return;
    }
    const CGPoint topLeft = {
        layout.left,
        layout.top,
    };
    const CGPoint bottomRight = {
        topLeft.x + layout.width,
        topLeft.y + layout.height,
    };
    const CGPoint origin = preserveOrigin ? view.frame.origin : CGPointZero;
    view.frame = (CGRect) {
        .origin = {
            .x = (topLeft.x + origin.x),
            .y = (topLeft.y + origin.y),
        },
        .size = {
            .width = (bottomRight.x) - (topLeft.x),
            .height = (bottomRight.y) - (topLeft.y),
        },
    };
    for (UIView *subview in view.subviews) {
        // 隐去系统的内部视图类
        if ([NSStringFromClass(subview.class) hasPrefix:@"_UI"]) {
            continue;
        }
        if (subview.layoutM.isEnabled && subview.layoutM.isIncludedInLayout) {
            HIUIApplyLayoutToViewHierarchy(subview, preserveOrigin);
        }
    }
}

@end


