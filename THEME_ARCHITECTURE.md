# 系统版本与主题接入

`MetroApp.version` 选择 WP7 / WP8 / WP8.1；`themeMode` 选择亮暗/系统；MediaQuery.highContrast 提供高对比度状态。

- 组件读取 `MetroSystemThemeData.of(context)` 获取 version、highContrast，不自行增加版本参数。
- 视觉颜色/字体从 ThemeData.colorScheme、textTheme 和组件专用 ThemeExtension 获取。
- 页面参数由 MetroPageThemeData.forVersion 生成；版本参数不做 Theme 插值，正在播放的转场锁定开始时的配置。
- 用户传入 theme 的同类型 extension 优先于生成默认值。增加新组件时：增加其 ThemeExtension、在 buildMetroExtensions 注册默认值，组件读取该扩展并提供缺省值。
- 高对比度状态已贯通；三代完整高对比度颜色资源尚未提取，不把普通亮暗色当作高对比度还原。

## Turnstile

四状态角度与 Log150/Exp150 来自 UIX Animations。WP8.1 In=300ms、Out=128ms，depth=80（用户明确指定的单位假设）；WP7/8 In=350ms、Out=167ms、depth=0。X 按容器宽度 ±10% 换算，原生坐标解释仍需设备投影核对。保留原项目全局透视。
Alpha 属于默认 Turnstile 内部：入场0→10ms线性0→1；退场 WP7/8 在166→167ms、WP8.1在126→128ms线性1→0。didFinish 取消轨道并恢复正常显示，避免给自定义 Panorama 入场额外叠加 Alpha。

## Application Bar

WP7 保持同一 bar View identity，恢复前提交的跨页连续宿主；WP8/8.1 按页面 owner 更换 View。此为应用内部导航行为，不声称 Flutter 可以控制跨进程系统 Application Bar。
新增资源核对：WP7 ShellFrame Assets ApplicationBarShow/Hide 均100ms，EaseIn(10,.5)；WP8与8.1显示200ms Log150，隐藏100ms EaseIn(10,.5)。当前 overlay 显示时长按版本切换，WP8/8.1显示曲线Log150。EaseIn(10,.5) 已追踪至 UIXRender 求值实现，并用 WP7/8 原始 x86 分段求值代码验证数值。WP7菜单开/关400/200ms均用该曲线；WP8/8.1均用Log150。已移除bounceOut及8.1特设easeOut。整栏位移固定72×.8而非按当前菜单高度计算；WP8/8.1在旧页退场阶段隐藏栏，新页登记时重新出现。

## 验证

版本关键帧、ApplicationBar与布局31项测试通过。全套118项通过，2项失败：原副本复测同样失败（空metro_ui_test文件、Panorama字号期望40而实际53.333）。未修改旧断言掩盖失败。
