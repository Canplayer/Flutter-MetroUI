# 系统版本与主题接入

项目结构、默认文字排版及逆向落地规则见 [技术规范](TECHNICAL_SPEC.md)。

`MetroApp` 和 `MetroApp.router` 默认使用 `MetroDesignVersion.wp8`。可通过 `version`、`themeMode`、`metroColor` 和 `highContrast` 调整全局预设。省略 `highContrast` 时读取系统设置。`MetroThemeData.fromPreset` 默认同样使用 WP8。

普通 Flutter 应用可以从 `package:metro_ui/metro_theme.dart` 导入独立主题，并仅包住需要的子树。

```dart
MetroTheme(
  data: const MetroThemeData.fromPreset(
    version: MetroDesignVersion.wp81,
    brightness: Brightness.light,
    accentColor: Colors.indigo,
    extensions: [
      MetroToggleSwitchTheme(borderColor: Colors.blueGrey),
    ],
  ),
  child: ToggleSwitch(value: enabled, onChanged: updateEnabled),
)
```

在 WP8 应用内单独使用 WP7 应用栏时，将版本和配色直接传给栏。应用级栏由 Navigator 外的 overlay 绘制，因此单栏应通过此入口指定预设。

```dart
const MetroApplicationBar(
  theme: MetroThemeData.fromPreset(
    version: MetroDesignVersion.wp7,
    accentColor: Colors.teal,
    extensions: [MetroAppBarTheme(buttonIconColor: Colors.teal)],
  ),
)
```

显式组件参数优先，其次是组件主题扩展，再使用预设默认值。局部预设重建组件默认值，省略的亮暗、对比度和强调色取外层环境。普通 Material 宿主首次应用 Metro 预设时，默认强调色为 Metro 蓝。强制高对比度时，默认强调色使用高对比度前景，可显式覆盖。主题只作用于子树，不引入导航器或全局缩放。

组件默认值位于 `lib/src/theme/component_defaults.dart`。组件接受自己的 ThemeExtension，或使用共享的语义颜色和文字样式。版本行为通过 `MetroSystemThemeData.of(context)` 读取。已实现库级高对比度配色，系统原版的完整高对比度资源仍需验证。

各组件可以继续在同一预设内独立配置。

| 控件 | 自定义入口 |
| --- | --- |
| AppBar、菜单和圆形按钮 | MetroAppBarTheme、单个栏的 theme、按钮实例颜色、尺寸与边框 |
| MetroButton | MetroButtonThemeData、实例颜色、边框宽度与内外边距 |
| EditBox、ToggleSwitch | MetroEditBoxTheme、MetroToggleSwitchTheme |
| ListPicker | MetroListPickerTheme，或实例的 style；展开到新路由时保留发起位置的主题 |
| 单行、双行列表项 | MetroListItemTheme、实例文字样式、leading 和 trailing |
| StackPanel、Pivot 标题、Panorama | MetroHeadingTheme、MetroTitleTextTheme、PanoramaConfig；StackPanel 和 Panorama 也支持实例文字样式 |
| 进度条与进度环 | MetroProgressTheme、实例前景色和尺寸 |
| ContextMenu | MetroContextMenuThemeData、实例动画配置、菜单项按下颜色 |
| Tile、PivotPaneView、页面与滚动 | 现有手势、运动及布局配置；颜色和字体由内容及主题提供 |

## Turnstile

四状态角度与 Log150/Exp150 来自 UIX Animations。WP8.1 In=300ms、Out=128ms，depth=80（用户明确指定的单位假设）；WP7/8 In=350ms、Out=167ms、depth=0。X 按容器宽度 ±10% 换算，原生坐标解释仍需设备投影核对。保留原项目全局透视。
Alpha 属于默认 Turnstile 内部：入场0→10ms线性0→1；退场 WP7/8 在166→167ms、WP8.1在126→128ms线性1→0。didFinish 取消轨道并恢复正常显示，避免给自定义 Panorama 入场额外叠加 Alpha。

## Application Bar

WP7 保持同一 bar View identity，恢复前提交的跨页连续宿主；WP8/8.1 按页面 owner 更换 View。此为应用内部导航行为，不声称 Flutter 可以控制跨进程系统 Application Bar。
新增资源核对：WP7 ShellFrame Assets ApplicationBarShow/Hide 均100ms，EaseIn(10,.5)；WP8与8.1显示200ms Log150，隐藏100ms EaseIn(10,.5)。当前 overlay 显示时长按版本切换，WP8/8.1显示曲线Log150。EaseIn(10,.5) 已追踪至 UIXRender 求值实现，并用 WP7/8 原始 x86 分段求值代码验证数值。WP7菜单开/关400/200ms均用该曲线；WP8/8.1均用Log150。已移除bounceOut及8.1特设easeOut。整栏位移固定72×.8而非按当前菜单高度计算；WP8/8.1在旧页退场阶段隐藏栏，新页登记时重新出现。
