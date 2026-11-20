// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metro_ui/metro_scroll_behavior.dart';
import 'package:metro_ui/page_scaffold.dart';

import './application_bar.dart';
import './route_aware_provider.dart';
import './metro_theme.dart';
import './uix_metrics.dart';
import './widgets/uix_popup.dart';

/// 描述 [MetroApp]能使用哪些主题.
enum MetroThemeMode {
  /// 使用亮色和暗色取决于系统设置.
  system,

  /// 总是使用亮色.
  light,

  /// 总是使用暗色模式（如果可用）而不考虑系统偏好.
  dark,
}

/// 应用程序使用 Metro Design.
///
/// 一个方便的小部件，它包装了许多常用于 Metro Design 应用程序的小部件。
/// 它在 [WidgetsApp] 的基础上添加了特定于 Metro Design 的功能，例如 [AnimatedTheme] 和 [GridPaper]。
///
/// 路由和应用栏继承当前预设的默认文字样式。
///
/// [MetroApp] 配置顶层 [Navigator] 按以下顺序搜索路由：
///
///  1. 对于 `/` 路由，如果 [home] 属性不为 null，则使用它。
///
///  2. 否则，使用 [routes] 表，如果它有该路由的条目。
///
///  3. 否则，如果提供了 [onGenerateRoute]，则调用它。它应为任何 [home] 和 [routes] 未处理的有效路由返回非 null 值。
///
///  4. 最后，如果所有方法都失败，则调用 [onUnknownRoute]。
///
/// 如果创建了一个 [Navigator]，则必须由以下一种选项处理 `/` 路由，因为它在启动时使用无效的 [initialRoute] 指定时会被使用
/// （例如通过其他应用程序在 Android 上启动此应用程序的意图；请参见 [dart:ui.PlatformDispatcher.defaultRouteName]）。
///
/// {@template flutter.material.MaterialApp.defaultSelectionStyle}
/// [MetroApp] 自动创建一个 [DefaultSelectionStyle]。如果 [ThemeData.textSelectionTheme] 中的颜色不为 null，则使用它们；
/// 否则，[MetroApp] 将 [DefaultSelectionStyle.selectionColor] 设置为 [ColorScheme.primary]，不透明度为 0.4，
/// 并将 [DefaultSelectionStyle.cursorColor] 设置为 [ColorScheme.primary]。
/// {@endtemplate}
///
/// 如果 [home]、[routes]、[onGenerateRoute] 和 [onUnknownRoute] 全部为 null，
/// 且 [builder] 不为 null，则不会创建 [Navigator]。
///
/// {@tool snippet}
/// 此示例展示了如何创建一个禁用“debug”横幅的 [MetroApp]，并设置一个在应用启动时显示的 [home] 路由。
///
/// ![MaterialApp 显示一个 Scaffold ](https://flutter.github.io/assets-for-api-docs/assets/material/basic_material_app.png)
///
/// ```dart
/// MaterialApp(
///   home: Scaffold(
///     appBar: AppBar(
///       title: const Text('Home'),
///     ),
///   ),
///   debugShowCheckedModeBanner: false,
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// 此示例展示了如何创建一个使用 [routes] `Map` 来定义 “home” 路由和 “about” 路由的 [MetroApp]。
///
/// ```dart
/// MaterialApp(
///   routes: <String, WidgetBuilder>{
///     '/': (BuildContext context) {
///       return Scaffold(
///         appBar: AppBar(
///           title: const Text('Home Route'),
///         ),
///       );
///     },
///     '/about': (BuildContext context) {
///       return Scaffold(
///         appBar: AppBar(
///           title: const Text('About Route'),
///         ),
///       );
///      }
///    },
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// 此示例展示了如何创建一个定义 [theme] 的 [MetroApp]，该主题将用于应用中的 Material 组件。
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     brightness: Brightness.dark,
///     primaryColor: Colors.blueGrey
///   ),
///   home: Scaffold(
///     appBar: AppBar(
///       title: const Text('MaterialApp Theme'),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// 另请参见：
///
///  * [MetroPageScaffold]，提供标准的应用程序元素，如 [AppBar] 和 [Drawer]。
///  * [Navigator]，用于管理应用程序的页面堆栈。
///  * [MaterialPageRoute]，定义以特定于Material的方式过渡的应用程序页面。
///  * [WidgetsApp]，定义基本的应用程序元素，但不依赖于材Material库。
///  * Flutter 国际化教程，
///    <https://flutter.dev/to/internationalization/>.
class MetroApp extends StatefulWidget {
  /// 创建一个使用 Metro Design 的应用程序.
  ///
  /// 至少一个 [home]、[routes]、[onGenerateRoute] 或 [builder] 必须不为 null。
  /// 如果只提供了 [routes]，则必须包含 [Navigator.defaultRouteName] (`/`) 的条目，
  /// 因为这是当应用程序以指定其他不支持的路由的意图启动时使用的路由。
  ///
  /// 此类创建一个 [WidgetsApp] 的实例。
  const MetroApp({
    this.version = MetroDesignVersion.wp8,
    this.highContrast,
    super.key,
    this.navigatorKey,
    this.home,
    Map<String, WidgetBuilder> this.routes = const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    this.onNavigationNotification,
    List<NavigatorObserver> this.navigatorObservers =
        const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.metroColor,
    this.themeMode = MetroThemeMode.dark,
    this.fontFamily,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior = const MetroScrollBehavior(),
    this.themeAnimationStyle,
    this.useWVGAMode = false,
  }) : routeInformationProvider = null,
       routeInformationParser = null,
       routerDelegate = null,
       backButtonDispatcher = null,
       routerConfig = null;

  ///创建一个使用 [Router] 而不是 [Navigator] 的 [MetroApp]。
  ///
  /// {@macro flutter.widgets.WidgetsApp.router}
  const MetroApp.router({
    this.version = MetroDesignVersion.wp8,
    this.highContrast,
    super.key,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.color,
    this.metroColor,
    this.themeMode = MetroThemeMode.dark,
    this.fontFamily,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
    this.themeAnimationStyle,
    this.useWVGAMode = false,
  }) : assert(routerDelegate != null || routerConfig != null),
       navigatorObservers = null,
       navigatorKey = null,
       onGenerateRoute = null,
       home = null,
       onGenerateInitialRoutes = null,
       onUnknownRoute = null,
       routes = null,
       initialRoute = null;

  /// {@macro flutter.widgets.widgetsApp.navigatorKey}
  final GlobalKey<NavigatorState>? navigatorKey;

  /// {@macro flutter.widgets.widgetsApp.home}
  final Widget? home;

  /// 应用程序的顶级路由表。
  ///
  /// 当使用 [Navigator.pushNamed] 推送一个命名路由时，路由名称会在此映射中查找。如果名称存在，
  /// 关联的 [widgets.WidgetBuilder] 将用于构造一个 [MaterialPageRoute]，该路由会执行适当的过渡，
  /// 切换到新路由。
  ///
  /// {@macro flutter.widgets.widgetsApp.routes}
  final Map<String, WidgetBuilder>? routes;

  /// {@macro flutter.widgets.widgetsApp.initialRoute}
  final String? initialRoute;

  /// {@macro flutter.widgets.widgetsApp.onGenerateRoute}
  final RouteFactory? onGenerateRoute;

  /// {@macro flutter.widgets.widgetsApp.onGenerateInitialRoutes}
  final InitialRouteListFactory? onGenerateInitialRoutes;

  /// {@macro flutter.widgets.widgetsApp.onUnknownRoute}
  final RouteFactory? onUnknownRoute;

  /// {@macro flutter.widgets.widgetsApp.onNavigationNotification}
  final NotificationListenerCallback<NavigationNotification>?
  onNavigationNotification;

  /// {@macro flutter.widgets.widgetsApp.navigatorObservers}
  final List<NavigatorObserver>? navigatorObservers;

  /// {@macro flutter.widgets.widgetsApp.routeInformationProvider}
  final RouteInformationProvider? routeInformationProvider;

  /// {@macro flutter.widgets.widgetsApp.routeInformationParser}
  final RouteInformationParser<Object>? routeInformationParser;

  /// {@macro flutter.widgets.widgetsApp.routerDelegate}
  final RouterDelegate<Object>? routerDelegate;

  /// {@macro flutter.widgets.widgetsApp.backButtonDispatcher}
  final BackButtonDispatcher? backButtonDispatcher;

  /// {@macro flutter.widgets.widgetsApp.routerConfig}
  final RouterConfig<Object>? routerConfig;

  /// {@macro flutter.widgets.widgetsApp.builder}
  ///

  /// Material 特定功能，如 [showDialog] 和 [showMenu]，以及小部件，
  /// 如 [Tooltip]、[PopupMenuButton]，还需要一个 [Navigator] 来正确运行。
  final TransitionBuilder? builder;

  /// {@macro flutter.widgets.widgetsApp.title}
  ///
  /// 这个值不会被修改，会直接传递给 [WidgetsApp.title]。
  final String title;

  /// {@macro flutter.widgets.widgetsApp.onGenerateTitle}
  ///
  /// 这个值不会被修改，会直接传递给 [WidgetsApp.onGenerateTitle]。
  final GenerateAppTitle? onGenerateTitle;

  /// Metro应用程序的主题颜色
  final Color? metroColor;

  /// Determines how the Metro preset selects its brightness. Defaults to dark.
  final MetroThemeMode themeMode;

  /// 应用的默认字体家族（默认：'Segoe WP'）。
  /// 如果你使用了 assets 字体，请在 pubspec.yaml 中声明并传入与之对应的 family 名称。
  final String? fontFamily;

  /// {@macro flutter.widgets.widgetsApp.color}
  final Color? color;

  /// {@macro flutter.widgets.widgetsApp.locale}
  final Locale? locale;

  /// {@macro flutter.widgets.widgetsApp.localizationsDelegates}
  ///
  /// 本地化保持flutter原有的实现，用户可以通过传入localizationsDelegates来覆盖默认的Material和Cupertino本地化。
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// {@macro flutter.widgets.widgetsApp.localeListResolutionCallback}
  ///
  /// 此回调被传递到此小部件构建的 [WidgetsApp]。
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// {@macro flutter.widgets.LocaleResolutionCallback}
  ///
  /// 此回调被传递到此小部件构建的 [WidgetsApp]。
  final LocaleResolutionCallback? localeResolutionCallback;

  /// {@macro flutter.widgets.widgetsApp.supportedLocales}
  ///
  /// 它被原样传递到此小部件构建的 [WidgetsApp]。
  ///
  /// 参见：
  ///
  ///  * [localizationsDelegates]，本地化应用程序时必须指定。
  ///  * [GlobalMaterialLocalizations]，一种
  ///    [localizationsDelegates] 的值，
  ///    提供多种语言的材料本地化。
  ///  * Flutter 国际化教程，
  ///    <https://flutter.dev/to/internationalization/>.
  final Iterable<Locale> supportedLocales;

  /// 打开性能叠加。
  ///
  /// 参见:
  ///
  ///  * <https://flutter.dev/to/performance-overlay>
  final bool showPerformanceOverlay;

  /// 打开一个覆盖层，显示框架报告的辅助功能信息。
  final bool showSemanticsDebugger;

  /// {@macro flutter.widgets.widgetsApp.debugShowCheckedModeBanner}
  final bool debugShowCheckedModeBanner;

  /// {@macro flutter.widgets.widgetsApp.shortcuts}
  /// {@tool snippet}
  /// 这个例子展示了如何为 [LogicalKeyboardKey.select] 添加一个快捷方式
  /// 到默认的快捷方式中，而无需添加你自己的 [Shortcuts] widget。
  ///
  /// 或者，你可以在 [WidgetsApp] 和其子级之间插入一个只包含你想要添加的映射的
  /// [Shortcuts] widget 来达到相同的效果。
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return WidgetsApp(
  ///     shortcuts: <ShortcutActivator, Intent>{
  ///       ... WidgetsApp.defaultShortcuts,
  ///       const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
  ///     },
  ///     color: const Color(0xFFFF0000),
  ///     builder: (BuildContext context, Widget? child) {
  ///       return const Placeholder();
  ///     },
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  /// {@macro flutter.widgets.widgetsApp.shortcuts.seeAlso}
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// {@macro flutter.widgets.widgetsApp.actions}
  /// {@tool snippet}
  /// 这个例子展示了如何为 [ActivateAction] 添加一个处理该动作的单一动作到默认的动作中，
  /// 而无需添加你自己的 [Actions] widget。
  ///
  /// 或者，你可以在 [WidgetsApp] 和其子级之间插入一个只包含你想添加的映射的
  /// [Actions] widget 来达到相同的效果。
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return WidgetsApp(
  ///     actions: <Type, Action<Intent>>{
  ///       ... WidgetsApp.defaultActions,
  ///       ActivateAction: CallbackAction<Intent>(
  ///         onInvoke: (Intent intent) {
  ///           // 在这里做些事情...
  ///           return null;
  ///         },
  ///       ),
  ///     },
  ///     color: const Color(0xFFFF0000),
  ///     builder: (BuildContext context, Widget? child) {
  ///       return const Placeholder();
  ///     },
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  /// {@macro flutter.widgets.widgetsApp.actions.seeAlso}
  final Map<Type, Action<Intent>>? actions;

  /// {@macro flutter.widgets.widgetsApp.restorationScopeId}
  final String? restorationScopeId;

  /// 应用程序的默认 [ScrollBehavior]。
  ///
  /// [ScrollBehavior] 描述了 [Scrollable] 小部件的行为。提供
  /// 一个 [ScrollBehavior] 可以设置整个应用的默认 [ScrollPhysics]，
  /// 并管理像 [Scrollbar] 这样的 [Scrollable] 装饰。
  ///
  /// 默认使用 [MetroScrollBehavior]。
  ///
  /// 另请参见：
  ///
  ///  * [ScrollConfiguration]，它控制子树中 [Scrollable] 小部件的行为。
  final ScrollBehavior? scrollBehavior;

  /// 打开一个 [GridPaper] 覆盖层，用于绘制基线网格在Material应用程序中。
  ///
  /// 只在调试模式下可用。
  ///
  /// 参见：
  ///
  ///  * <https://material.io/design/layout/spacing-methods.html>
  final bool debugShowMaterialGrid;

  /// Controls the theme transition. Defaults to 200 ms with a linear curve.
  /// Use [AnimationStyle.noAnimation] for an immediate theme change.
  final AnimationStyle? themeAnimationStyle;

  /// 启用 WVGA 模式（480px 设计稿缩放）
  ///
  /// 当设置为 true 时，UI 将按照 480px 宽度的设计稿进行缩放，
  /// 以适配不同尺寸的设备屏幕。这对于还原 Windows Phone 原版体验很有帮助。
  ///
  /// 默认为 false。
  final bool useWVGAMode;

  /// The design version of the Metro UI.
  final MetroDesignVersion version;

  /// Overrides the platform contrast setting when supplied.
  final bool? highContrast;

  @override
  State<MetroApp> createState() => _MetroAppState();
}

class _MetroAppState extends State<MetroApp> {
  final MetroAppBarController _appBarController = MetroAppBarController();

  @override
  void dispose() {
    _appBarController.dispose();
    super.dispose();
  }

  bool get _usesRouter =>
      widget.routerDelegate != null || widget.routerConfig != null;

  // 将 Material 的本地化与 localizationsDelegates 参数中提供的本地化合并。
  // 某个特定 LocalizationsDelegate.type 的第一个委托将被加载，所以
  // localizationsDelegate 参数可以用来覆盖 _MaterialLocalizationsDelegate。
  Iterable<LocalizationsDelegate<dynamic>> get _localizationsDelegates {
    return <LocalizationsDelegate<dynamic>>[
      if (widget.localizationsDelegates != null)
        ...widget.localizationsDelegates!,
      DefaultMaterialLocalizations.delegate,
      DefaultCupertinoLocalizations.delegate,
    ];
  }

  ThemeData _themeBuilder(BuildContext context) {
    final brightness = switch (widget.themeMode) {
      MetroThemeMode.light => Brightness.light,
      MetroThemeMode.dark => Brightness.dark,
      MetroThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    final highContrast =
        widget.highContrast ?? MediaQuery.highContrastOf(context);
    return MetroThemeData.fromPreset(
      version: widget.version,
      brightness: brightness,
      highContrast: highContrast,
      accentColor: widget.metroColor,
    ).toThemeData(brightness: brightness, fontFamily: widget.fontFamily);
  }

  Widget _materialBuilder(BuildContext context, Widget? child) {
    final ThemeData theme = _themeBuilder(context);
    final Color effectiveSelectionColor =
        theme.textSelectionTheme.selectionColor ??
        theme.colorScheme.primary.withValues(alpha: 0.40);
    final Color effectiveCursorColor =
        theme.textSelectionTheme.cursorColor ?? theme.colorScheme.primary;

    Widget childWidget = child ?? const SizedBox.shrink();

    // Navigator（以及其内的所有路由/页面）之下垫一层主题背景色。
    //
    // 这里基于 WidgetsApp 而非 MaterialApp，路由之下并没有主题背景层，
    // 页面被平移离开后露出的是「平台原生底色」：桌面端 FlutterView 黑底、
    // Web 端浏览器白底。该底色与主题无关，于是同一段位移动画（例如页面推入/
    // 推出时整体上浮、下滑）在不同平台会露出不同颜色，表现为 Web 上露白。
    //
    // 在路由之下统一下垫一层 scaffoldBackgroundColor，让露出区域始终跟随主题，
    // 与 [MetroPageScaffold] 内部 Material 的背景色保持一致，实现跨平台表现统一。
    // 页面不透明且铺满整个路由时，该层被完全遮挡，不会产生任何视觉影响。
    childWidget = ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: childWidget,
    );

    {
      if (widget.builder != null) {
        childWidget = Builder(
          builder: (BuildContext context) {
            // 我们为什么要用一个 builder 包装另一个 builder？
            //
            // widget.builder 可能包含调用 Theme.of() 的代码，
            // 这应该返回我们在 AnimatedTheme 中选择的主题。
            // 然而，如果我们直接将 widget.builder() 作为 AnimatedTheme 的子级调用，
            // 那么它们之间就没有 Context 分隔，
            // widget.builder() 将无法找到主题。因此，我们用另一个 builder
            // 包裹 widget.builder，以便它们之间有一个 context 分隔，
            // 并且 Theme.of() 能正确解析为我们传递给 AnimatedTheme 的主题。
            return widget.builder!(
              context,
              ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      }
      final content = childWidget;
      childWidget = AnimatedTheme(
        data: theme,
        duration: widget.themeAnimationStyle == AnimationStyle.noAnimation
            ? Duration.zero
            : widget.themeAnimationStyle?.duration ?? kThemeAnimationDuration,
        curve: widget.themeAnimationStyle?.curve ?? Curves.linear,
        child: Builder(
          builder: (context) => DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            child: Stack(
              children: [
                content,
                AnimatedBuilder(
                  animation: _appBarController,
                  builder: (context, child) => _appBarController.isExpanded
                      ? Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _appBarController.closeMenu,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MetroApplicationBarOverlay(
                    controller: _appBarController,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultSelectionStyle(
      selectionColor: effectiveSelectionColor,
      cursorColor: effectiveCursorColor,
      child: UixPopupLayer(child: childWidget),

      // Stack(
      //   children: [
      //     childWidget,
      //     Positioned(
      //       left: 0,
      //       right: 0,
      //       bottom: 0,
      //       child: MetroApplicationBarOverlay(controller: _appBarController),
      //     ),
      //   ],
      // ),
    );
  }

  /// 构建 WVGA 模式的 DPI 转换层
  ///
  /// 使用 FractionallySizedBox + Transform.scale 实现全局 UI 缩放，
  /// 并修正 MediaQuery 中的系统边距参数（如软键盘高度）。
  Widget _buildMetroUIDPIConversion(BuildContext context, Widget child) {
    // 如果未启用 WVGA 模式，直接返回原始 widget
    if (!widget.useWVGAMode) {
      return child;
    }

    // WVGA 标准宽度为 480px
    const double targetDesignWidth = 480.0 * 0.8;

    final originalData = MediaQuery.of(context);
    final double deviceWidth = originalData.size.width;

    if (deviceWidth == 0) {
      return child;
    }

    // 计算缩放因子 (SF)
    // SF = 实际设备逻辑宽度 / 目标设计宽度
    // 例如: 320 / 480 = 0.6667 (内容需要缩小到 0.6667 倍)
    final double scaleFactor = deviceWidth / targetDesignWidth;

    // 计算 FractionallySizedBox 的因子 (layoutFactor)
    // layoutFactor = 1 / SF = W_target / W_device
    // 例如: 480 / 320 = 1.5 (内容将在 1.5 倍于屏幕宽度的空间内布局)
    final double layoutFactor = 1.0 / scaleFactor;

    // --- 修正 MediaQueryData ---
    // 将系统报告的边距（如软键盘、刘海高度）按比例反向缩放
    // 缩放后的值 = 原始值 / scaleFactor (也就是 * layoutFactor)
    // 这样在经过下方的 Transform.scale 缩放回来后，在物理屏幕上刚好等于正确的边距真实大小高度
    final double inverseLayoutFactor = layoutFactor;

    final MediaQueryData fixedData = originalData.copyWith(
      // 修正 viewInsets (软键盘遮挡)
      viewInsets: originalData.viewInsets * inverseLayoutFactor,
      // 修正 viewPadding (系统刘海/手势条)
      viewPadding: originalData.viewPadding * inverseLayoutFactor,
      // 修正 padding (物理屏幕边距)
      padding: originalData.padding * inverseLayoutFactor,
    );

    return MediaQuery(
      data: fixedData, // 使用修正后的 MediaQueryData
      child: FractionallySizedBox(
        // 放大可用空间，让 480 宽度的内容可以在其中布局
        widthFactor: layoutFactor,
        heightFactor: layoutFactor,
        alignment: Alignment.topLeft, // 确保内容从左上角开始布局
        child: Transform.scale(
          // 缩小内容，将其放回屏幕实际可见范围
          scale: scaleFactor,
          alignment: Alignment.topLeft, // 确保从左上角开始缩放
          child: child,
        ),
      ),
    );
  }

  Widget _buildWidgetApp(BuildContext context) {
    final appColor = widget.color ?? Colors.blue;
    if (_usesRouter) {
      return WidgetsApp.router(
        key: GlobalObjectKey(this),
        routeInformationProvider: widget.routeInformationProvider,
        routeInformationParser: widget.routeInformationParser,
        routerDelegate: widget.routerDelegate,
        routerConfig: widget.routerConfig,
        backButtonDispatcher: widget.backButtonDispatcher,
        onNavigationNotification: widget.onNavigationNotification,
        builder: _materialBuilder,
        title: widget.title,
        onGenerateTitle: widget.onGenerateTitle,
        color: appColor,
        locale: widget.locale,
        localizationsDelegates: _localizationsDelegates,
        localeResolutionCallback: widget.localeResolutionCallback,
        localeListResolutionCallback: widget.localeListResolutionCallback,
        supportedLocales: widget.supportedLocales,
        showPerformanceOverlay: widget.showPerformanceOverlay,
        showSemanticsDebugger: widget.showSemanticsDebugger,
        debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
        shortcuts: widget.shortcuts,
        actions: widget.actions,
        restorationScopeId: widget.restorationScopeId,
      );
    }

    return WidgetsApp(
      key: GlobalObjectKey(this),
      navigatorKey: widget.navigatorKey,
      navigatorObservers: [routeObserver, ...widget.navigatorObservers!],
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return builder(context);
              },
        );
      },
      home: widget.home,
      routes: widget.routes!,
      initialRoute: widget.initialRoute,
      onGenerateRoute: widget.onGenerateRoute,
      onGenerateInitialRoutes: widget.onGenerateInitialRoutes,
      onUnknownRoute: widget.onUnknownRoute,
      onNavigationNotification: widget.onNavigationNotification,
      builder: _materialBuilder,
      title: widget.title,
      onGenerateTitle: widget.onGenerateTitle,
      color: appColor,
      locale: widget.locale,
      localizationsDelegates: _localizationsDelegates,
      localeResolutionCallback: widget.localeResolutionCallback,
      localeListResolutionCallback: widget.localeListResolutionCallback,
      supportedLocales: widget.supportedLocales,
      showPerformanceOverlay: widget.showPerformanceOverlay,
      showSemanticsDebugger: widget.showSemanticsDebugger,
      debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
      shortcuts: widget.shortcuts,
      actions: widget.actions,
      restorationScopeId: widget.restorationScopeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 构建 WidgetsApp (获取基础 Context 和原始 MediaQueryData)
    Widget result = _buildWidgetApp(context);

    // 2.建立全局3D透视转换层，开发者写3D动画无需再考虑摄像机位置
    //全局3D坐标观察点固定到屏幕中心
    result = Transform(
      alignment: FractionalOffset.center,
      transform: Matrix4.identity()..setEntry(3, 2, uixPerspective),
      child: result,
    );

    // 3. 将 WidgetsApp 的结果包裹在 DPI 转换组件中
    // 这一步实现了全局缩放和软键盘/系统边距的修正
    result = _buildMetroUIDPIConversion(context, result);

    // 4. 后续的 Focus、GridPaper 和 ScrollConfiguration 等全局包裹
    result = Focus(
      canRequestFocus: false,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
            event.logicalKey != LogicalKeyboardKey.escape) {
          return KeyEventResult.ignored;
        }
        return Tooltip.dismissAllToolTips()
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: result,
    );
    assert(() {
      if (widget.debugShowMaterialGrid) {
        result = GridPaper(
          color: const Color(0xE0F9BBE0),
          interval: 8.0,
          subdivisions: 1,
          child: result,
        );
      }
      return true;
    }());

    return MetroAppBarScope(
      controller: _appBarController,
      child: ScrollConfiguration(
        behavior: widget.scrollBehavior ?? const MetroScrollBehavior(),
        child: result,
      ),
    );
  }
}
