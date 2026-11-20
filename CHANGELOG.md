## 未发布

- 新增 `MetroPageHeader` 和 `MetroPageScaffold.header`，集中管理页面标题与固定单栏目标题的默认排版。Pivot 继续管理自己的栏目标题。
- 移除旧页眉、输入框和选择器别名。输入框从 `widgets/edit_box.dart` 导入，选择器从 `widgets/list_picker.dart` 导入。
- 统一应用主题入口，使用 `themeAnimationStyle` 配置主题动画。文字缩放使用 Flutter 的 `TextScaler`。

## 0.0.1

项目初始版本。
