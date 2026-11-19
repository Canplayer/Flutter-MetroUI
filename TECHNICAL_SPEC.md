# Flutter Metro UI 技术规范

本规范适用于 `metro_ui` 框架，涵盖应用入口、组件、使用约定和 WP 原版行为的移植流程。框架默认使用 **WP8**。WP7 和 WP8.1 可显式选择，覆盖度按控件和行为分别核对。

## 应用框架

| 层级 | 入口和职责 |
| --- | --- |
| 应用根节点 | [`MetroApp` / `MetroApp.router`](lib/app.dart) 基于 `WidgetsApp`，负责路由入口、主题、默认文字样式、页面底色、可选 WVGA 视口缩放，以及 Navigator 外的 Application Bar overlay。 |
| 主题 | [`MetroThemeData` / `MetroTheme`](lib/metro_theme.dart) 构建应用或子树预设。[`MetroSystemThemeData`](lib/metro_theme_extensions.dart) 提供系统版本和高对比度状态。组件默认项由 [`component_defaults.dart`](lib/src/theme/component_defaults.dart) 和各控件的主题扩展消费点维护。 |
| 页面 | [`MetroPageScaffold`](lib/page_scaffold.dart) 管理页面主体、独立底色、系统边距、软件返回、页面动画回调和 Application Bar 注册。`useMaterialSurface` 为依赖 Ink 的子控件提供兼容表面。 |
| 导航 | [`MetroPageRoute`](lib/page.dart) 配合 [`metroPagePush`](lib/metro_page_push.dart) 执行导航。推入前先等待当前页的退场，再调用 `Navigator.push`。调用点在 Scaffold 子树之外时传 `scaffoldKey`。默认让 `Navigator.maybePop` 走页面的返回处理和退场生命周期。 |
| 动画 | [`MetroAnimatedPage`](lib/animations.dart) 承载默认 Turnstile。`UixPageSlide` 与 `UixPopupRoute` 用于原版另有指定轨道的页面和弹层。`MetroAppBarController` 根据导航 owner 和版本管理应用栏宿主。 |

`MetroApp`、`MetroApp.router` 和 `MetroThemeData.fromPreset` 的 `version` 默认为 `MetroDesignVersion.wp8`。`MetroApp` 两个构造函数的 `themeMode` 默认为 `.dark`，`useWVGAMode` 默认为 `false`。需要随系统切换亮暗时传入 `MetroThemeMode.system`，需要其他版本时显式传入 `MetroDesignVersion.wp7` 或 `.wp81`。

应用入口示例使用框架默认的 WP8 预设。

```dart
const MetroApp(
  home: MetroPageScaffold(
    body: Center(child: Text('settings')),
  ),
)
```

在普通 Flutter 应用中使用部件时，可用 `MetroTheme` 包住对应子树。局部应用栏预设传给 `MetroApplicationBar.theme`，因为它挂载在路由子树之外。组件有显式实例参数时优先使用，其次使用它的主题扩展和预设默认值。保留调用方提供的文字样式、字体及显式行高。[主题参数与版本轨道](THEME_ARCHITECTURE.md)

### 导航与叠层

- 默认页面把无透视的主题底色放在动画内容层后面。Application Bar 在 Navigator 外按页面登记，WP7 使用连续宿主，WP8 和 WP8.1 按 owner 更换。这里实现的是 Flutter 内部导航行为。
- 页面原版指定独立转场时，按对应方向禁用默认轨道，再接入自定义回调。分别核对进入、返回进入、推出和退出，检查透明度是否属于该轨道。Panorama 入场、页面 Slide 和对话框 Swivel 各有独立轨道。
- 软件返回使用 `MetroPageScaffold` 的 `showSoftwareBackButton` 和原有 `ic_back.svg` 适配触屏。这是 `MetroPageScaffold` 为触屏提供的软件返回入口。排版、图标或动画修正涉及该区域时，保持既有位置、尺寸和外观，除非任务明确要求改变。

## 控件接入

| 场景 | 组件及调用约定 |
| --- | --- |
| 操作按钮 | `MetroButton` 接收 `child` 和 `onTap`。原版标签可直接传 `Text`。`MetroCircleButton`、`MetroAppBarButton` 保持各自的按压、可用状态和标签显示规则。 |
| 列表与长按 | `SingleLineListItem`、`DoubleLineListItem` 接收标题和样式。`PushableDoubleLineListItem` 用于有独立文字按压轨道和前导操作区的条目。长按菜单通过 `MetroContextMenu`。 |
| 设置 | `ToggleSwitch` 提供完整标题、状态和描述。`ToggleSwitchBase` 适合从原版模板单独复用开关本体。`ListPicker<T>` 用相同值类型定义列表、当前值和 `onChanged`。 |
| 输入和搜索 | `EditBox` 是通用输入接口。`UixEditBox` 直接持有 Flutter `EditableText`，调用方提供 controller、focus 和原版背景图。`MetroSearchBar` 复用此输入件装配搜索。controller 与 focus 的创建方负责释放。 |
| 加载与弹层 | `ProgressBar` 为线形进度，`ProgressRing` 为环形进度。普通双按钮确认先创建 `MetroMessageBox` 实例，再调用 `show(context)`。需要原版弹层运动的自定义内容使用 `UixPopupRoute`。 |
| 横向布局 | `Pivot`、`PivotStack` 接收 `PivotItem`，`PivotPaneView` 负责页面容器。`MetroPanorama` 管理背景、标题、内容视差及吸附。`StackPanel` 适合已有标题组合。 |
| 数字键盘 | `PhoneKeypad` 处理数字键手势、长按和键面布局。输入内容及命令处理由宿主通过回调管理。 |

### 文字规范

- 业务页面默认写 `Text(...)`。`MetroApp` 的默认 UIX 标签用 Segoe WP Regular、15 pt 换算后字号、零字距。传给 `MetroButton(child: Text(...))` 等已有控件的文字，由控件内部选择排版规则。
- 新控件确认原版 `BoundsType = 7` 时，可在内部使用 `UixTightText`。单行字符串使用 `UixTightText('history')`，富文本用 `.rich(...)`，保留已有 `Text` 参数用 `.fromText(...)`。这一实现按原版 Segoe WP 的 ASCII 字形测量单行垂直边界。中文回退字体、其他字体、显式行高与实际换行段落沿用 Flutter 常规布局。
- `BoundsType` 跟随原版文字角色。标准 UIX `LabelStyle` 默认为 7，普通 Pivot 标题用 5，Panorama 大标题用 4。Flutter 通用行高系数无法表达不同字形的边界。原版多行 `LineSpacing` 和通用 `CharacterSpacing` 换算仍需核对。
- 字体统一注册为 `Segoe WP`，借助 [`UixFontWeight`](lib/uix_typography.dart) 选字型。Light 300、SemiLight 350、Regular 400、SemiBold 600、Bold 700、Black 800。Flutter 清单只允许声明整百值，SemiLight 条目省略 `weight`，由引擎从字体文件读取 350。调用时用 `FontWeight(350)`。

## 从 WP 源码落实到 Flutter

### 证据和单位

1. 先确认系统版本、屏幕资源集、语言、亮暗和高对比度变体。记录模块、资源路径、类、方法或对象段偏移。区分 UIX 对象段偏移、PE 文件偏移和虚拟地址。
2. 从使用点反查实际绑定的模板、样式、资源常量和事件。在样式继承、多分辨率和状态切换处继续追到最终值。同一模块可能有名称和外观相近的多套资源。以模板在当前状态下实际绑定的资源为依据。
3. 保留原值、原单位、换算表达式和生效位置。480 宽设计单位的坐标、边距和位图尺寸乘 `uixScale`（0.8）。UIX `FontSize` 为点，`UIXRender` 先乘 `96 / 72`，Flutter 通过 [`uixFontSize`](lib/uix_metrics.dart) 再乘 0.8。54 pt 得到 57.6 逻辑像素，43 设计单位得到 34.4 逻辑像素。视口的 WVGA 缩放位于应用根层，控件内部按本项目逻辑单位布局一次。
4. 拆开可见像素、位图画布、边距、内边距、命中区和九宫格切片。复用图像保留透明边和完整状态素材，记录资源标识、原始尺寸及 SHA-256。UIX 属性的单位或继承未确定时，把现有实现假设写入记录，避免以相似数值替换。

### 实现和验收

1. 分别核对结构、主题、交互和动画。颜色追到语义槽及系统版本，交互核对点击、长按、拖出取消、禁用、焦点、返回及交替点击区域。还原 UIX 外观时沿用现有 Metro 部件或 Flutter 底层能力，避免把 Material 控件的默认边框、涟漪、字体和转场带入原版视觉层。
2. 动画记录触发者、目标节点、总时长、各属性关键帧、曲线参数、投影坐标和锚点。`Log(150)`、`Exp(150)`、`EaseIn(10, .5)` 用公共实现。透明度按时间轴独立核算。WP8.1 Turnstile 的 Z=100 UIX 单位目前按约定解释为 100 dp，再乘 0.8 得到 80，注明该单位假设。原版 3D 投影的实机核对仍是独立验证项。
3. 记录证据状态。资源值、反汇编或原机测量明确支持的内容标为已确认。由原值换算的结果写出公式。宿主适配、量测推定和未验证的原版行为各自注明。Flutter 截图和回归测试证明实现行为，原机逐帧或同基准截图才支持原机像素级结论。
4. 提交前在框架仓库运行 `flutter test`，通过真实公开入口覆盖改动。文字变更检查默认 `Text`、显式样式、窄宽换行和主题范围。动画测起点、关键时间和终点。触屏流程测入口到返回，资源核查不同主题和按压状态。对照原版的验收还需提供对应证据。

### 返工经验与验收规则

| 曾出现的问题 | 以后在实现和验收时怎么检查 |
| --- | --- |
| 按观感用 Material 组件或自定义组合拼出近似界面。 | 先确认原版部件名称、继承关系和模板，再决定复用或新增控件。拆开父容器排列、内部状态、热区和动画归属。基础控件用原版名称，例如 `ProgressRing`。验收时比对实际组件树和交互轨道。 |
| 把父级的弹跳、显隐或 3D 倾斜加到子项上。 | 查触发事件和动画真正绑定的节点。标签装配与显隐由控制它的层级管理。分别测点击、长按、拖离和取消，确认独立热区保持原版行为。原版已确认的特殊行为和缺陷也纳入验收。 |
| 把同名近似的位图当成实际资源，或顺手替换现成图标。 | 从控件的状态绑定追到原文件，再核对文件尺寸、透明边和哈希。记录可见图形和点击范围的区别。用户已确认的图标、位置及操作入口按现有约定保留。 |
| 为避免重叠而自行缩小软件返回，或因为原机有实体键而在触屏上关掉软件返回。 | 把框架的软件返回当作已存在的公共交互。排版修改单独处理。用带可返回路由的可见预览检查原 SVG、尺寸、偏移和透明度，再点按验证返回。 |
| 原始字号直接乘布局系数，或用第二个字体族绕开 350 字重。 | 点字号使用 `uixFontSize`，布局使用 `uixScale`。核查 TTF 中的 `usWeightClass`，并验证实际引擎选中的字型。保持 `Segoe WP` 的单一字体族约定。 |
| 清除 Material 行高后就认为所有文字边界一致，或直接把每个 `Text` 换成紧边界标签。 | 区分自然行框、可见字形和原版 `BoundsType`。普通页面继续用 `Text`，对应原版角色的控件内部选择测量方式。测试窄宽换行、显式行高和自定义字体，并注明单行与字符覆盖范围。 |
| 把应用配置、测试夹具或原版参数的推定值写成框架默认。 | 通用默认值以公开构造函数和预设为准。本库默认 WP8。移植记录分列原值、换算结果、适配选择和待验证项。用默认调用路径和指定版本分别验收。 |
| 测试通过就把外观宣称为像素级一致。 | 测试覆盖行为和数值，视觉结论需要相同分辨率、主题和状态的实际渲染对照。提交说明写清已经检查的范围。 |

### 提交边界

框架提交包含控件、公共行为、实际使用的资源、对应测试和维护文档。系统镜像、临时反汇编、验收截图和 Flutter 构建产物保存在研究区或临时目录。每项还原应能通过源码定位、原版资料记录或回归测试复核。
