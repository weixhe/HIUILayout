//
//  HIUILayoutManager.h
//  HIUILayout
//
//  Created by weixhe on 2020/12/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 布局主轴方向枚举
 */
typedef NS_ENUM(NSUInteger, HIUIFlexDirection) {
    HIUIFlexDirectionHorizontal,       /// 水平方向, 行
    HIUIFlexDirectionVertical,    /// 垂直方向, 列
};

/**
 布局折行枚举
 */
typedef NS_ENUM(NSUInteger, HIUIFlexWrap) {
    HIUIFlexWrapNoWrap,
    HIUIFlexWrapWrap,
};

/**
 内容的布局对齐方式枚举：主轴
 */
typedef NS_ENUM(NSUInteger, HIUIFlexJustify) {
    HIUIFlexJustifyStart,
    HIUIFlexJustifyStartAround,
    HIUIFlexJustifyCenter,
    HIUIFlexJustifyEnd,
    HIUIFlexJustifyEndAround,
};

/**
 视图的布局对齐方式枚举：交叉轴
 */
typedef NS_ENUM(NSUInteger, HIUIFlexAlign) {
    HIUIFlexAlignDefault,
    HIUIFlexAlignStart,
    HIUIFlexAlignCenter,
    HIUIFlexAlignEnd,
};

/**
 HIUI 提供的布局管理类
 
 Flex是Flexible Box的缩写，意为”弹性布局”，用来为盒状模型提供最大的灵活性。
 任何一个视图View都可以指定为Flex布局。
 
 视图view默认存在两根轴：水平的主轴（main axis）和垂直的交叉轴（cross axis）。主轴的开始位置（与边框的交叉点）叫做main start，结束位置叫做main end；交叉轴的开始位置叫做cross start，结束位置叫做cross end。
 项目默认沿主轴排列。单个项目占据的主轴空间叫做main size，占据的交叉轴空间叫做cross size。
 
 以下属性设置在父视图view上：
 flexDirection：决定了主轴的方向（即视图view的排列方向）。
    - HIUIFlexDirectionRow：水平方向
    - HIUIFlexDirectionColumn：垂直方向
 flexWrap：决定了视图在轴线上排布折行方式
    - HIUIFlexWrapNoWrap：不折行排布，多余的视图可能会被裁掉
    - HIUIFlexWrapWrap：折行排布
 justifyContent：决定了视图在主轴上的对齐方式。
    - HIUIFlexJustifyStart：左对齐
    - HIUIFlexJustifyStartAround,
    - HIUIFlexJustifyCenter：居中
    - HIUIFlexJustifyEnd：右对齐
    - HIUIFlexJustifyEndAround,
 alignItems：决定了视图在交叉轴上的对齐方式。
    - HIUIFlexAlignStart：交叉轴的起点对齐。
    - HIUIFlexAlignCenter：交叉轴的中点对齐。
    - HIUIFlexAlignEnd：交叉轴的终点对齐。
 
 以下属性设置在子视图subview上:
 flexGrow：定义子视图的放大比例，默认为0，即如果存在剩余空间，也不放大。
 flexShrik：定义了子视图的缩小比例，默认为0，即如果空间不足，该子视图不缩小，将被裁剪。
 
 */
@interface HIUILayoutManager : NSObject

/// 应用布局
/// @param preserveOrigin 是否保留原来的坐标，即在原来的起始位置的基础上再次计算布局
- (void)applyLayoutPreservingOrigin:(BOOL)preserveOrigin;

@property (nonatomic, assign, setter=setIncludedInLayout:) BOOL isIncludedInLayout;
@property (nonatomic, assign, setter=setEnabled:) BOOL isEnabled;   /// 用于设置 View 是否能够进行布局

@property (nonatomic, assign) HIUIFlexDirection flexDirection;      /// 主轴方向
@property (nonatomic, assign) HIUIFlexWrap flexWrap;                /// 是否允许折行
@property (nonatomic, assign) HIUIFlexJustify justifyContent;       /// 主轴布局方式
@property (nonatomic, assign) HIUIFlexAlign alignItems;             /// 交叉轴布局方式

@property (nonatomic, assign) CGFloat left;     /// 最外层父视图可以设置left值
@property (nonatomic, assign) CGFloat top;      /// 最外层父视图可以设置top值
@property (nonatomic, assign) CGFloat right;    /// 最外层父视图可以设置right值
@property (nonatomic, assign) CGFloat bottom;   /// 最外层父视图可以设置bottom值
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) CGFloat aspectRatio; /// 用于设置宽高比

@property (nonatomic, assign) CGFloat paddingLeft;      /// 设置内边距-左，约束子视图的位置
@property (nonatomic, assign) CGFloat paddingTop;       /// 设置内边距-上，约束子视图的位置
@property (nonatomic, assign) CGFloat paddingRight;     /// 设置内边距-右，约束子视图的位置
@property (nonatomic, assign) CGFloat paddingBottom;    /// 设置内边距-下，约束子视图的位置
@property (nonatomic, assign) CGFloat padding;          /// 设置内边距，约束子视图的位置

@property (nonatomic, assign) CGFloat marginLeft;   /// 设置间距-左，两个子视图之间的距离
@property (nonatomic, assign) CGFloat marginTop;    /// 设置间距-上，两个子视图之间的距离
@property (nonatomic, assign) CGFloat marginRight;  /// 设置间距-右，两个子视图之间的距离
@property (nonatomic, assign) CGFloat marginBottom; /// 设置间距-下，两个子视图之间的距离
@property (nonatomic, assign) CGFloat margin;       /// 设置间距，视图中所有子视图之间的距离

/// 子视图拉伸比例。当父视图宽度(或高度)大于子视图宽度(或高度)总和时子视图拉伸比例
/// 如果所有子视图的flexGrow属性都为1，则它们将等分剩余空间（如果有的话）。
/// 如果一个子视图的flexGrow属性为2，其他子视图为1，则前者占据的剩余空间将比其他子视图多一倍。
/// 默认 0，即如果存在剩余空间，也不拉伸
@property (nonatomic, assign) CGFloat flexGrow;

/// 子视图收缩规则。当父视图宽度(或高度)小于子视图宽度(或高度)总和时子视图收缩比例
/// 如果所有子视图的flexShrik属性都为1，当空间不足时，都将等比例缩小。
/// 如果一个子视图的flexShrik属性为0，其他子视图都为1，则空间不足时，前者不缩小。
/// 默认 0，即如果没有足够空间，也不缩小
@property (nonatomic, assign) CGFloat flexShrik;

/// 设置布局每行的子视图的数量，如果为0，则沿着主轴方向逐个布局，如果当前行剩余空间不足，则自动折行
@property (nonatomic, assign) NSUInteger flexCount;
@property (nonatomic, assign) NSUInteger flexNumberOfLine;  /// 设置布局行数
@property (nonatomic, assign) BOOL hidden;      // 默认 NO
@property (nonatomic, assign) BOOL fitSizeSelf; // 默认 YES, 如果不需要自适应自身尺寸, 则设置宽高, 或把此参数置为 NO

@end

NS_ASSUME_NONNULL_END
