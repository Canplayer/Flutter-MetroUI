# Flutter Metro UI 技术规范

本规范记录组件库 `metro_ui` 和相邻应用 `windows_phone_simulator` 的实际结构、调用约定，以及从 WP 原版证据落实到 Flutter 的工作方法。WP7、WP8、WP8.1 的预设覆盖度按控件和行为分别核对。

## 应用框架

| 层级 | 入口和职责 |
| --- | --- |
| 应用根节点 | [`MetroApp` / `MetroApp.router`](lib/app.dart) 基于 `WidgetsApp`，负责路由入口、主题、默认文字样式、页面底色、可选 WVGA 视口缩放，以及 Navigator 外的 Application Bar overlay。 |
| 主题 | [`MetroThemeData` / `MetroTheme`](lib/metro_theme.dart) 构建应用或子树预设。[`MetroSystemThemeData`](lib/metro_theme_extensions.dart) 提供系统版本和高对比度状态。组件默认项由 [`component_defaults.dart`](lib/src/theme/component_defaults.dart) 和各控件的主题扩展消费点维护。 |
| 页面 | [`MetroPageScaffold`](lib/page_scaffold.dart) 管理页面主体、独立底色、系统边距、软件返回、页面动画回调和 Application Bar 注册。`useMaterialSurface` 为依赖 Ink 的子控件提供兼容表面。 |
| 导航 | [`MetroPageRoute`](lib/page.dart) 配合 [`metroPagePush`](lib/metro_page_push.dart) 执行导航。推入前先等待当前页的退场，再调用 `Navigator.push`。调用点在 Scaffold 子树之外时传 `scaffoldKey`。默认让 `Navigator.maybePop` 走页面的返回处理和退场生命周期。 |
| 动画 | [`MetroAnimatedPage`](lib/animations.dart) 承载默认 Turnstile。`UixPageSlide` 与 `UixPopupRoute` 用于原版另有指定轨道的页面和弹层。`MetroAppBarController` 根据导航 owner 和版本管理应用栏宿主。 |
| 模拟器 | `main.dart` 注册应用并从 `Splashscreen` 进入 `LauncherPage`。`AppRegistry` 提供开始屏、磁贴和应用列表数据。`apps/phone` 装配电话历史、拨号器、设置和通话壳。 |

应用入口用 `MetroApp(version: ..., themeMode: ..., metroColor: ..., highContrast: ..., home: ...)`。在普通 Flutter 应用中使用部件时，可用 `MetroTheme` 包住对应子树。局部应用栏预设传给 `MetroApplicationBar.theme`，因为它挂载在路由子树之外。组件有显式实例参数时优先使用，其次使用它的主题扩展和预设默认值。保留调用方提供的文字样式、字体及显式行高。[主题参数与版本轨道](THEME_ARCHITECTURE.md)

模拟器根节点选择 WP8.1 并开启 `useWVGAMode`，电话应用通过自己的主题子树固定到 WP8。电话页面和原版资源的装配留在模拟器，可复用控件、公共转场与默认值留在组件库。电话格式化、拨号、联系人、详情和语音信箱按宿主回调接入。未接宿主服务的演示行为按模拟器实现记录。

### 导航与叠层

- 默认页面把无透视的主题底色放在动画内容层后面。Application Bar 在 Navigator 外按页面登记，WP7 使用连续宿主，WP8 和 WP8.1 按 owner 更换。这里实现的是 Flutter 内部导航行为。
- 页面原版指定独立转场时，按对应方向禁用默认轨道，再接入自定义回调。分别核对进入、返回进入、推出和退出，检查透明度是否属于该轨道。Panorama 的自定义入场、电话拨号页的 Slide 和对话框的 Swivel 均有各自的轨道。
- 软件返回使用 `MetroPageScaffold` 的 `showSoftwareBackButton` 和原有 `ic_back.svg` 适配触屏。它属于模拟器补充交互。排版、图标或动画修正涉及该区域时，保持既有位置、尺寸和外观，除非任务明确要求改变。

## 控件接入

| 场景 | 组件及调用约定 |
| --- | --- |
| 操作按钮 | `MetroButton` 接收 `child` 和 `onTap`。原版标签可直接传 `Text`。`MetroCircleButton`、`MetroAppBarButton` 保持各自的按压、可用状态和标签显示规则。 |
| 列表与长按 | `SingleLineListItem`、`DoubleLineListItem` 接收标题和样式。`PushableDoubleLineListItem` 用于电话历史这类独立文字按压轨道及前导操作区。长按菜单通过 `MetroContextMenu`。 |
| 设置 | `ToggleSwitch` 提供完整标题、状态和描述。`ToggleSwitchBase` 适合从原版模板单独复用开关本体。`ListPicker<T>` 用相同值类型定义列表、当前值和 `onChanged`。 |
| 输入和搜索 | `EditBox` 是通用输入接口。`UixEditBox` 直接持有 Flutter `EditableText`，调用方提供 controller、focus 和原版背景图。`MetroSearchBar` 复用此输入件装配搜索。controller 与 focus 的创建方负责释放。 |
| 加载与弹层 | `ProgressBar` 为线形进度，`ProgressRing` 为环形进度。普通双按钮确认先创建 `MetroMessageBox` 实例，再调用 `show(context)`。需要原版弹层运动的自定义内容使用 `UixPopupRoute`。 |
| 横向布局 | `Pivot`、`PivotStack` 接收 `PivotItem`，`PivotPaneView` 负责页面容器。`MetroPanorama` 管理背景、标题、内容视差及吸附。`StackPanel` 适合已有标题组合。 |
| 电话键盘 | `PhoneKeypad` 处理数字键输入、长按和键面布局。拨号、通话、粘贴、删除及保存联系人由宿主页控制。 |

### 文字规范

- 业务页面默认写 `Text(...)`。`MetroApp` 的默认 UIX 标签用 Segoe WP Regular、15 pt 换算后字号、零字距。传给 `MetroButton(child: Text(...))` 等已有控件的文字，由控件内部选择排版规则。
- 新控件确认原版 `BoundsType = 7` 时，可在内部使用 `UixTightText`。单行字符串使用 `UixTightText('history')`，富文本用 `.rich(...)`，保留已有 `Text` 参数用 `.fromText(...)`。这一实现按原版 Segoe WP 的 ASCII 字形测量单行垂直边界。中文回退字体、其他字体、显式行高与实际换行段落沿用 Flutter 常规布局。
- `BoundsType` 跟随原版文字角色。电话历史标签用 7，普通 Pivot 标题用 5，Panorama 大标题用 4，搜索联系人入口用 2。Flutter 通用行高系数无法表达不同字形的边界。原版多行 `LineSpacing` 和通用 `CharacterSpacing` 换算仍需核对。
- 字体统一注册为 `Segoe WP`，借助 [`UixFontWeight`](lib/uix_typography.dart) 选字型。Light 300、SemiLight 350、Regular 400、SemiBold 600、Bold 700、Black 800。Flutter 清单只允许声明整百值，SemiLight 条目省略 `weight`，由引擎从字体文件读取 350。调用时用 `FontWeight(350)`。

## 从 WP 源码落实到 Flutter

### 证据和单位

1. 先确认系统版本、屏幕资源集、语言、亮暗和高对比度变体。记录模块、资源路径、类、方法或对象段偏移。区分 UIX 对象段偏移、PE 文件偏移和虚拟地址。
2. 从使用点反查实际绑定的模板、样式、资源常量和事件。在样式继承、多分辨率和状态切换处继续追到最终值。电话历史回拨曾误用相近的 `PHONE.CALLBACK.*`（62×62）。实际 `PhoneButtonRest/Down` 绑定 `PHONE.LISTITEM.*`（43×43）。资源存在只证明系统具备该资源。
3. 保留原值、原单位、换算表达式和生效位置。480 宽设计单位的坐标、边距和位图尺寸乘 `uixScale`（0.8）。UIX `FontSize` 为点，`UIXRender` 先乘 `96 / 72`，Flutter 通过 [`uixFontSize`](lib/uix_metrics.dart) 再乘 0.8。54 pt 得到 57.6 逻辑像素，43 设计单位得到 34.4 逻辑像素。视口的 WVGA 缩放位于应用根层，控件内部按本项目逻辑单位布局一次。
4. 拆开可见像素、位图画布、边距、内边距、命中区和九宫格切片。复用图像保留透明边和完整状态素材，记录资源标识、原始尺寸及 SHA-256。UIX 属性的单位或继承未确定时，把现有实现假设写入记录，避免以相似数值替换。

### 实现和验收

1. 分别核对结构、主题、交互和动画。颜色追到语义槽及系统版本，交互核对点击、长按、拖出取消、禁用、焦点、返回及交替点击区域。还原 UIX 外观时沿用现有 Metro 部件或 Flutter 底层能力，避免把 Material 控件的默认边框、涟漪、字体和转场带入原版视觉层。
2. 动画记录触发者、目标节点、总时长、各属性关键帧、曲线参数、投影坐标和锚点。`Log(150)`、`Exp(150)`、`EaseIn(10, .5)` 用公共实现。透明度按时间轴独立核算。WP8.1 Turnstile 的 Z=100 UIX 单位目前按约定解释为 100 dp，再乘 0.8 得到 80，注明该单位假设。原版 3D 投影的实机核对仍是独立验证项。
3. 记录证据状态。资源值、反汇编或原机测量明确支持的内容标为已确认。由原值换算的结果写出公式。宿主适配、量测推定和未验证的原版行为各自注明。Flutter 截图和回归测试证明实现行为，原机逐帧或同基准截图才支持原机像素级结论。
4. 提交前运行受影响仓库的实际入口测试。文字变更检查默认 `Text`、显式样式、窄宽换行和主题范围。动画测起点、关键时间和终点。触屏流程测入口到返回，资源核查不同主题和按压状态。项目级验收以两仓库 `flutter test` 结果为准。

### 提交边界

组件库与模拟器是独立 Git 仓库，模拟器以 `../Flutter-MetroUI` 作为本地依赖。涉及两端的改动分别提交，并在交付时记录两个提交 ID。原始系统镜像、临时反汇编、验收截图与 Flutter 构建产物保存在研究区或临时目录。项目提交包含实际使用的资源、实现、测试与维护文档。
