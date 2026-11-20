# Flutter Metro UI 技术规范

本规范适用于 `metro_ui` 框架，涵盖应用入口、组件、使用约定和 WP 原版行为的移植流程。框架默认使用 **WP8**。WP7 和 WP8.1 可显式选择，覆盖度按控件和行为分别核对。

## 应用框架

| 层级 | 入口和职责 |
| --- | --- |
| 应用根节点 | [`MetroApp` / `MetroApp.router`](lib/app.dart) 基于 `WidgetsApp`，负责路由入口、主题、默认文字样式、页面底色、可选 WVGA 视口缩放，以及 Navigator 外的 Application Bar overlay。 |
| 主题 | [`MetroThemeData` / `MetroTheme`](lib/metro_theme.dart) 构建应用或子树预设。[`MetroSystemThemeData`](lib/metro_theme_extensions.dart) 提供系统版本和高对比度状态。组件默认项由 [`component_defaults.dart`](lib/src/theme/component_defaults.dart) 和各控件的主题扩展消费点维护。 |
| 页面 | [`MetroPageScaffold`](lib/page_scaffold.dart) 管理页面主体、独立底色、系统边距、软件返回、页面动画回调和 Application Bar 注册。`useMaterialSurface` 为依赖 Ink 的子控件提供 Material 绘制层。 |
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
| 设置 | `ToggleSwitch` 提供完整标题、状态和描述。`ToggleSwitchBase` 适合从原版模板单独复用开关本体。[`ListPicker<T>`](lib/widgets/list_picker.dart) 用相同值类型定义列表、当前值和 `onChanged`。 |
| 输入和搜索 | [`EditBox`](lib/widgets/edit_box.dart) 是通用输入接口。`UixEditBox` 直接持有 Flutter `EditableText`，调用方提供 controller、focus 和原版背景图。`MetroSearchBar` 复用此输入件装配搜索。controller 与 focus 的创建方负责释放。 |
| 加载与弹层 | `ProgressBar` 为线形进度，`ProgressRing` 为环形进度。普通双按钮确认先创建 `MetroMessageBox` 实例，再调用 `show(context)`。需要原版弹层运动的自定义内容使用 `UixPopupRoute`。 |
| 页面标题 | `MetroPageScaffold.header` 接收 `MetroPageHeader`。`title` 显示页面标题，`singlePivotHeader` 显示单栏目页的大标题，两者直接传 `Text` 即可使用系统默认样式。`MetroHeadingTheme` 可覆盖两种样式。 |
| 横向布局 | `Pivot`、`PivotStack` 接收 `PivotItem`，由 `PivotHeader` 绘制栏目标题，`PivotPaneView` 负责页面容器。`MetroPanorama` 管理背景、标题、内容视差及吸附。 |
| 数字键盘 | `PhoneKeypad` 处理数字键手势、长按和键面布局。输入内容及命令处理由宿主通过回调管理。 |

### 页面小标题与栏目标题

`MetroPageHeader.title` 对应原版 `PageHeader` 的 `TitleHost` 插槽。原版在这里装入 `DefaultPageTitleContent` 或 `Page.TitleType` 指定的标题内容。直接传 `Text` 即可使用 WP8 默认的 17 pt SemiBold。固定单栏目页可以另外传 `singlePivotHeader`，它使用 54 pt SemiLight。两种字号都已按 `uixFontSize` 的比例换算，页眉负责安全区和默认边距。

有 Pivot 的页面把栏目名传给 `PivotItem.title`，把对应内容传给 `PivotItem.page`。Pivot 自己负责栏目标题的样式、选中状态和移动。需要暂时隐藏栏目标题时使用 `Pivot.showHeader`。`MetroPageHeader.titleGap` 在普通页面默认使用 56 个设计单位，搭配 `singlePivotHeader` 时默认使用 24 个设计单位。搭配独立 Pivot 时可传 `24 * uixScale`，专用页面可按资源覆盖。

```dart
const MetroPageScaffold(
  header: MetroPageHeader(
    title: Text('SETTINGS'),
    singlePivotHeader: Text('phone'),
  ),
  body: Center(child: Text('Settings content')),
)
```

### 圆框和图标

`MetroCircleButton` 和 `MetroAppBarButton` 默认绘制矢量圆框。调用方可以给 `icon` 传入透明底的 SVG 或其他图案，圆框、按下填充和图案着色由控件处理。显式选择 `frameStyle: MetroCircleFrameStyle.classicBitmap` 时使用包内 WP8 Shell 圆框 PNG，并把按下贴图的红色填充映射到当前强调色。两种圆框共用按压状态和图标着色。自定义 `backgroundBuilder` 优先于预设圆框。

### 文字规范

页面默认写 `Text(...)`，由 `MetroApp` 或 `MetroTheme` 提供默认样式。默认 UIX 标签字号为 15 pt，使用 Segoe WP Regular 和零字距。把 `Text` 直接交给 Metro 控件的标签或标题槽时，控件按原版角色应用边界规则。自己实现 UIX 控件时，从 `package:metro_ui/widgets/uix_text.dart` 导入 `UixText`。

```dart
const UixText(
  'history',
  boundsType: UixTextBounds(
    alignToAscender: true,
    trimLeftSideBearing: true,
  ),
);

const UixText(
  'phone',
  boundsType: UixTextBounds.tight,
);
```

`UixText.rich(TextSpan(...))` 接受富文本。`UixText.fromText(text, boundsType: ...)` 保留传入的 `Text` 属性。单字符串与富文本构造函数也接受 `maxLines`、`softWrap`、`overflow` 和 `style`。默认边界为 `UixTextBounds.full`。

| 原版规则 | Dart 选项 | 作用 |
| --- | --- | --- |
| AlignToAscender | `alignToAscender` | 文字框的上边界落在字型的大写字高线。 |
| AlignToBaseline | `alignToBaseline` | 文字框底边收在字母基线。 |
| TrimLeftSideBearing | `trimLeftSideBearing` | 按起始字形的正左字承移动绘制位置并缩减宽度。 |
| Tight | `UixTextBounds.tight` | 组合以上三个选项。适用于标准 `LabelStyle`、页面小标题和 `SinglePivotHeader`。 |

| WP8 文字角色 | 边界规则 | 原版资源 |
| --- | --- | --- |
| 标准按钮、确认框文字及按钮、展开的 AppBar 圆钮标签、文字命令 | Tight | `UIXMobile!Button.uix`、`MessageBox.uix`、`ShellChrome!ApplicationBarItem.uix` 及其标签样式 |
| 页面小标题、单页大标题、列表行、开关标签、ListPicker 选项及全屏选择标题 | Tight | `UIXMobile!Page.uix`、`List.uix`、`ToggleSwitch.uix`、`ListPicker.uix`、`PickerBoxBase.uix` |
| 普通 Pivot 分栏标题 | AlignToAscender + TrimLeftSideBearing | `UIXMobile!Pivot.uix` |
| Panorama 大标题和分栏标题 | TrimLeftSideBearing | `UIXMobile!Panorama.uix` 的 `TitleText` 和 `HeaderText` |
| 上下文菜单文字、AppBar 菜单文字、ListPicker 占位文字 | Full | `ShellChrome!Menu.uix`、`ApplicationBarMenu.uix`、`UIXMobile!ListPicker.uix` 的原生 Text |

边界计算的原版入口见 `UIXRender.dll` VA `0x1005ec4d`（垂直）和 `0x1005f051` 至 `0x1005f224`（水平）。标题之间的间距从布局框边缘计算，裁切和字形可见范围分别由控件的视口和 Flutter 绘制处理。

布局层解析 `FontManifest.json` 中已注册的静态 TTF、OTF 字型，每个资源包按字体族缓存。读取 `head`、`OS/2`、`hhea`、`cmap`、`hmtx` 等表，按实际字号与缩放换算。字体资源随现有 `pubspec.yaml` 声明即可。需要首帧就使用边界度量时，在页面显示前可调用 `UixText.preloadFontMetrics(family)`。控件可以直接嵌入普通 Flutter 应用。需要隔离宿主继承的字号或行高时，可以用局部 `MetroTheme`。

当前垂直计算覆盖能解析到同一个静态字型的单行文字，包括只改变颜色的文字段。水平字承覆盖从左到右、起始对齐的普通拉丁标签，按首字符映射的字形读取字承。实际发生换行、使用未知系统回退字型、混合字号或显式行高的文字沿用 Flutter 排版。字形替换、复杂文字方向和多行原版边界仍需独立核对。

本库字体注册为 `Segoe WP`，借助 [`UixFontWeight`](lib/uix_typography.dart) 选择 Light 300、SemiLight 350、Regular 400、SemiBold 600、Bold 700、Black 800。Flutter 清单只允许声明整百值，SemiLight 条目省略 `weight`，引擎和度量读取器均使用该字体文件的字重 350。调用时用 `FontWeight(350)`。

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
| 清除 Material 行高后就认为所有文字边界一致，或直接把每个 `Text` 换成紧边界标签。 | 区分自然行框、可见字形和原版 `BoundsType`。普通页面继续用 `Text`，对应原版角色的控件内部选择测量方式。测试窄宽换行、显式行高和自定义字体，并注明已验证的文字方向、字型和换行范围。 |
| 把应用配置、测试夹具或原版参数的推定值写成框架默认。 | 通用默认值以公开构造函数和预设为准。本库默认 WP8。移植记录分列原值、换算结果、适配选择和待验证项。用默认调用路径和指定版本分别验收。 |
| 测试通过就把外观宣称为像素级一致。 | 测试覆盖行为和数值，视觉结论需要相同分辨率、主题和状态的实际渲染对照。提交说明写清已经检查的范围。 |

### 提交边界

框架提交包含控件、公共行为、实际使用的资源、对应测试和维护文档。系统镜像、临时反汇编、验收截图和 Flutter 构建产物保存在研究区或临时目录。每项还原应能通过源码定位、原版资料记录或回归测试复核。
