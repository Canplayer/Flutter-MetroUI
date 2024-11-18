// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metro_ui/merto/page.dart';

// import 'arc.dart';
// import 'colors.dart';
// import 'floating_action_button.dart';
// import 'icons.dart';
// import 'material_localizations.dart';
// import 'page.dart';
// import 'scaffold.dart' show ScaffoldMessenger, ScaffoldMessengerState;
// import 'scrollbar.dart';
// import 'theme.dart';
// import 'tooltip.dart';

// 示例可以假设：
// typedef GlobalWidgetsLocalizations = DefaultWidgetsLocalizations;
// typedef GlobalMaterialLocalizations = DefaultMaterialLocalizations;

/// [MetroApp] 使用这个 [TextStyle] 作为其 [DefaultTextStyle]，以鼓励
/// 开发者对他们的 [DefaultTextStyle] 保持有意为之。
///
/// 在 Material 设计中，大多数 [Text] 小部件包含在 [Material] 小部件中，
/// 它设置了特定的 [DefaultTextStyle]。如果你看到使用这个文本样式的文本，
/// 考虑将你的文本放在一个 [Material] 小部件中（或其他设置了 [DefaultTextStyle] 的小部件）。
const TextStyle _errorTextStyle = TextStyle(
  color: Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48.0,
  fontWeight: FontWeight.w900,
  decoration: TextDecoration.underline,
  decorationColor: Color(0xFFFFFF00),
  decorationStyle: TextDecorationStyle.double,
  debugLabel: 'fallback style; consider putting your text in a Material',
);

/// 描述 [MetroApp]能使用哪些主题.
enum ThemeMode {
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
/// [MetroApp]配置其 [WidgetsApp.textStyle] 为一个丑陋的红色/黄色文本样式，旨在警告开发者他们的
/// 应用程序尚未定义默认文本样式。通常，应用程序的 [MetroPage] 构建一个 [Material] 小部件，
/// 其默认 [Material.textStyle] 定义了整个脚手架的文本样式。
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
/// 此小部件还配置顶级 [Navigator]（如果有）的观察者以执行 [Hero] 动画。
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
/// ## 故障排除
///
/// ### 为什么我的应用程序的文本是红色并带有黄色下划线？
///
/// 缺少 [Material] 父级的 [Text] 小部件将以难看的红色/黄色文本样式渲染。
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/material_app_unspecified_textstyle.png)
///
/// 典型的修复方法是为小部件提供一个 [MetroPage] 父级。[MetroPage] 创建一个 [Material] 小部件，定义其默认文本样式。
///
/// ```dart
/// const MaterialApp(
///   title: 'Material App',
///   home: Scaffold(
///     body: Center(
///       child: Text('Hello World'),
///     ),
///   ),
/// )
/// ```
///
/// 另请参见：
///
///  * [MetroPage]，提供标准的应用程序元素，如 [AppBar] 和 [Drawer]。
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
    super.key,
    this.navigatorKey,
    this.metroScaffoldMessengerKey,
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
    this.theme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode = ThemeMode.system,
    this.themeAnimationDuration = kThemeAnimationDuration,
    this.themeAnimationCurve = Curves.linear,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
    //移除此参数，因为它现在被忽略。MaterialApp 永远不会引入自己的 MediaQuery；View 小部件会处理它。
    @Deprecated('Remove this parameter as it is now ignored. '
        'MaterialApp never introduces its own MediaQuery; the View widget takes care of that. '
        'This feature was deprecated after v3.7.0-29.0.pre.')
    this.useInheritedMediaQuery = false,
    this.themeAnimationStyle,
  })  : routeInformationProvider = null,
        routeInformationParser = null,
        routerDelegate = null,
        backButtonDispatcher = null,
        routerConfig = null;

  ///创建一个使用 [Router] 而不是 [Navigator] 的 [MetroApp]。
  ///
  /// {@macro flutter.widgets.WidgetsApp.router}
  const MetroApp.router({
    super.key,
    this.metroScaffoldMessengerKey,
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
    this.theme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode = ThemeMode.system,
    this.themeAnimationDuration = kThemeAnimationDuration,
    this.themeAnimationCurve = Curves.linear,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
    @Deprecated('Remove this parameter as it is now ignored. '
        'MaterialApp never introduces its own MediaQuery; the View widget takes care of that. '
        'This feature was deprecated after v3.7.0-29.0.pre.')
    this.useInheritedMediaQuery = false,
    this.themeAnimationStyle,
  })  : assert(routerDelegate != null || routerConfig != null),
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

  /// 一个用于构建 [PageMessenger] 的键。
  ///

  /// 如果指定了 [metroScaffoldMessengerKey]，则可以直接操作 [PageMessenger]，
  /// 而无需通过 [BuildContext] 从 [PageMessenger.of] 获取：从 [metroScaffoldMessengerKey] 使用 [GlobalKey.currentState] getter。
  final GlobalKey<MetroPageMessengerState>? metroScaffoldMessengerKey;

  /// {@macro flutter.widgets.widgetsApp.home}
  final Widget? home;

  /// 应用程序的顶级路由表。
  ///
  /// 当使用 [Navigator.pushNamed] 推送一个命名路由时，路由名称会在此映射中查找。如果名称存在，
  /// 关联的 [widgets.WidgetBuilder] 将用于构造一个 [MaterialPageRoute]，该路由会执行适当的过渡，
  /// 包括 [Hero] 动画，切换到新路由。
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

  /// 默认的视觉属性，如颜色、字体和形状，适用于应用的材质组件。
  ///
  /// 可以指定一个额外的 [darkTheme] [ThemeData]，用于提供用户界面的暗色版本。
  /// 如果提供了 [darkTheme]，则 [themeMode] 将控制使用哪个主题。
  ///
  /// 此属性的默认值为 [ThemeData.light()]。
  ///
  /// 另请参阅：
  ///
  ///  * [themeMode]，用于控制使用哪个主题。
  ///  * [MediaQueryData.platformBrightness]，表示平台的期望亮度，
  /// 并在 [MetroApp] 中自动切换 [theme] 和 [darkTheme]。

  final ThemeData? theme;

  /// 当系统请求“暗模式”时使用的 [ThemeData]。
  ///
  /// 一些平台允许用户选择全局的“暗模式”，
  /// 或者应用程序可能希望为此应用程序选择一个暗主题。此主题将在
  /// 这种情况下使用。[themeMode] 将控制使用哪个主题。
  ///
  /// 此主题的 [ThemeData.brightness] 应设置为 [Brightness.dark]。
  ///
  /// 如果 [darkTheme] 和 [theme] 都为 null，则使用 [theme]。如果 [theme] 也为 null，
  /// 则默认为 [ThemeData.light()] 的值。
  ///
  /// 参见：
  ///
  ///  * [themeMode]，控制使用哪个主题。
  ///  * [MediaQueryData.platformBrightness]，表示平台所需的亮度，并在 [MetroApp] 中
  ///    用于自动在 [theme] 和 [darkTheme] 之间切换。
  ///  * [ThemeData.brightness]，通常设置为 [MediaQueryData.platformBrightness] 的值。
  final ThemeData? darkTheme;

  /// 当系统请求“高对比度”时使用的 [ThemeData]。
  ///
  /// 一些平台（例如 iOS）允许用户通过辅助功能设置增加对比度。
  ///
  /// 如果设置为 null，则使用 [theme]。
  ///
  /// 参见：
  ///
  ///  * [MediaQueryData.highContrast]，它表示平台希望增加对比度。
  final ThemeData? highContrastTheme;

  /// 当系统请求“暗黑模式”和“高对比度”时使用的 [ThemeData]。
  ///
  /// 一些主机平台（例如 iOS）允许用户通过辅助功能设置增加对比度。
  ///
  /// 此主题的 [ThemeData.brightness] 应设置为 [Brightness.dark]。
  ///
  /// 若为 null，则使用 [darkTheme]。
  ///
  /// 另请参见：
  ///
  ///  * [MediaQueryData.highContrast]，它指示平台是否希望增加对比度。
  final ThemeData? highContrastDarkTheme;

  /// 决定当同时提供 [theme] 和 [darkTheme] 时，应用程序将使用哪种主题。
  ///
  /// 如果设置为 [ThemeMode.system]，将根据用户的系统偏好来选择使用哪种主题。
  /// 如果 [MediaQuery.platformBrightnessOf] 是 [Brightness.light]，将使用 [theme]。
  /// 如果是 [Brightness.dark]，将使用 [darkTheme]（除非它为 null，此时将使用 [theme]）。
  ///
  /// 如果设置为 [ThemeMode.light]，无论用户的系统偏好如何，始终使用 [theme]。
  ///
  /// 如果设置为 [ThemeMode.dark]，无论用户的系统偏好如何，始终使用 [darkTheme]。
  /// 如果 [darkTheme] 为 null，则会退回使用 [theme]。
  ///
  /// 默认值是 [ThemeMode.system]。
  ///
  /// 另请参见：
  ///
  ///  * [theme]，当选择浅色模式时使用。
  ///  * [darkTheme]，当选择深色模式时使用。
  ///  * [ThemeData.brightness]，它指示系统的各个部分正在使用哪种类型的主题。
  final ThemeMode? themeMode;

  /// 动画主题更改的持续时间。
  ///
  /// 当主题更改时（通过更改 [theme]、[darkTheme] 或 [themeMode]
  /// 参数），会在一段时间内将其动画过渡到新主题。
  /// [themeAnimationDuration] 决定了动画所需的时间。
  ///
  /// 若要立即更改主题，可以将此值设置为 [Duration.zero]。
  ///
  /// 默认值为 [kThemeAnimationDuration]。
  ///
  /// 另请参见：
  ///   [themeAnimationCurve]，定义动画使用的曲线。
  final Duration themeAnimationDuration;

  /// 在应用主题变化时使用的曲线。
  ///
  /// 默认使用 [Curves.linear]。
  ///
  /// 如果 [themeAnimationDuration] 设置为 [Duration.zero]，
  /// 则忽略此设置。
  ///
  /// 另请参见：
  ///   [themeAnimationDuration]，定义动画的持续时间。
  final Curve themeAnimationCurve;

  /// {@macro flutter.widgets.widgetsApp.color}
  final Color? color;

  /// {@macro flutter.widgets.widgetsApp.locale}
  final Locale? locale;

  /// {@macro flutter.widgets.widgetsApp.localizationsDelegates}
  ///
  /// 需要为 [GlobalMaterialLocalizations] 列表中的某个区域设置提供翻译的国际化应用
  /// 应该指定此参数并列出应用程序可以处理的 [supportedLocales]。
  ///
  /// ```dart
  /// // GlobalMaterialLocalizations 和 GlobalWidgetsLocalizations
  /// // 类需要以下导入：
  /// // import 'package:flutter_localizations/flutter_localizations.dart';
  ///
  /// const MaterialApp(
  ///   localizationsDelegates: <LocalizationsDelegate<Object>>[
  ///     // ... 在这里添加针对应用的特定本地化委托
  ///     GlobalMaterialLocalizations.delegate,
  ///     GlobalWidgetsLocalizations.delegate,
  ///   ],
  ///   supportedLocales: <Locale>[
  ///     Locale('en', 'US'), // 英语
  ///     Locale('he', 'IL'), // 希伯来语
  ///     // ... 应用支持的其他区域
  ///   ],
  ///   // ...
  /// )
  /// ```
  ///
  /// ## 为新区域添加本地化
  ///
  /// 以下信息适用于应用为尚未由
  /// [GlobalMaterialLocalizations] 支持的语言添加翻译的特殊情况。
  ///
  /// 生成 [WidgetsLocalizations] 和 [MaterialLocalizations] 的委托是
  /// 自动包含的。应用程序可以通过创建
  /// [LocalizationsDelegate<WidgetsLocalizations>]
  /// 或 [LocalizationsDelegate<MaterialLocalizations>] 的实现并
  /// 在其加载方法中返回自定义版本的
  /// [WidgetsLocalizations] 或 [MaterialLocalizations] 来提供自己的版本。
  ///
  /// 例如：为 [MaterialLocalizations] 添加对它尚不支持的区域设置
  /// 的支持，比如 `const Locale('foo', 'BR')`，首先需要
  /// 创建一个提供翻译的 [MaterialLocalizations] 子类：
  ///
  /// ```dart
  /// class FooLocalizations extends MaterialLocalizations {
  ///   FooLocalizations();
  ///   @override
  ///   String get okButtonLabel => 'foo';
  ///   // ...
  ///   // 需要重写的其他许多 getter 和方法！
  /// }
  /// ```
  ///
  /// 然后必须创建一个 [LocalizationsDelegate] 子类，能够提供
  /// [MaterialLocalizations] 子类的实例。在这种情况下，这
  /// 基本上只是一个构造 `FooLocalizations` 对象的方法。
  /// 这里使用了 [SynchronousFuture]，因为在“加载”本地化对象时
  /// 不会进行异步工作。
  ///
  /// ```dart
  /// // 继续前一个示例...
  /// class FooLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  ///   const FooLocalizationsDelegate();
  ///   @override
  ///   bool isSupported(Locale locale) {
  ///     return locale == const Locale('foo', 'BR');
  ///   }
  ///   @override
  ///   Future<FooLocalizations> load(Locale locale) {
  ///     assert(locale == const Locale('foo', 'BR'));
  ///     return SynchronousFuture<FooLocalizations>(FooLocalizations());
  ///   }
  ///   @override
  ///   bool shouldReload(FooLocalizationsDelegate old) => false;
  /// }
  /// ```
  ///
  /// 使用 `FooLocalizationsDelegate` 构造一个 [MetroApp] 会覆盖
  /// 自动包含的 [MaterialLocalizations] 委托，因为
  /// 仅使用每个 [LocalizationsDelegate.type] 的第一个委托，
  /// 并且自动包含的委托被添加到应用的
  /// [localizationsDelegates] 列表的末尾。
  ///
  /// ```dart
  /// // 继续前一个示例...
  /// const MaterialApp(
  ///   localizationsDelegates: <LocalizationsDelegate<Object>>[
  ///     FooLocalizationsDelegate(),
  ///   ],
  ///   // ...
  /// )
  /// ```
  /// 参见：
  ///
  ///  * [supportedLocales]，必须与
  ///    [localizationsDelegates] 一起指定。
  ///  * [GlobalMaterialLocalizations]，一种
  ///    [localizationsDelegates] 的值，
  ///    为多种语言提供材料本地化。
  ///  * Flutter 国际化教程，
  ///    <https://flutter.dev/to/internationalization/>.
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

  /// 打开栅格缓存图像的查看器。
  final bool checkerboardRasterCacheImages;

  /// 打开渲染到离屏位图的图层的查看器。
  final bool checkerboardOffscreenLayers;

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

  /// {@template flutter.material.materialApp.scrollBehavior}
  /// 应用程序的默认 [ScrollBehavior]。
  ///
  /// [ScrollBehavior] 描述了 [Scrollable] 小部件的行为。提供
  /// 一个 [ScrollBehavior] 可以设置整个应用的默认 [ScrollPhysics]，
  /// 并管理像 [Scrollbar] 和 [GlowingOverscrollIndicator] 这样的
  /// [Scrollable] 装饰。
  /// {@endtemplate}
  ///
  /// 当为 null 时，默认为 [MaterialScrollBehavior]。
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

  /// {@macro flutter.widgets.widgetsApp.useInheritedMediaQuery}
  /// 此参数现在已被忽略。[MaterialApp] 永远不会引入自己的 [MediaQuery]；
  /// [View] 小部件会处理这个。此功能在 v3.7.0-29.0.pre 之后被弃用。
  @Deprecated('This setting is now ignored. '
      'MaterialApp never introduces its own MediaQuery; the View widget takes care of that. '
      'This feature was deprecated after v3.7.0-29.0.pre.')
  final bool useInheritedMediaQuery;

  /// 用于覆盖主题动画曲线和持续时间。
  ///
  /// 如果提供了 [AnimationStyle.duration]，它将用于覆盖底层 [AnimatedTheme] 小部件中的主题动画持续时间。
  /// 如果为 null，则将使用 [themeAnimationDuration]。否则，默认为 200ms。
  ///
  /// 如果提供了 [AnimationStyle.curve]，它将用于覆盖底层 [AnimatedTheme] 小部件中的主题动画曲线。
  /// 如果为 null，则将使用 [themeAnimationCurve]。否则，默认为 [Curves.linear]。
  ///
  /// 要禁用主题动画，请使用 [AnimationStyle.noAnimation]。
  ///
  /// {@tool dartpad}
  /// 这个示例展示了如何使用 [AnimationStyle] 在 [MetroApp] 小部件中覆盖主题动画曲线和持续时间。
  ///
  /// ** 请参阅 examples/api/lib/material/app/app.0.dart 中的代码 **
  /// {@end-tool}
  final AnimationStyle? themeAnimationStyle;

  @override
  State<MetroApp> createState() => _MetroAppState();

  ///  [HeroController] 用于 Material 页面过渡。
  ///
  /// 被 [MetroApp] 使用。
  static HeroController createMaterialHeroController() {
    return HeroController(
      createRectTween: (Rect? begin, Rect? end) {
        return MaterialRectArcTween(begin: begin, end: end);
      },
    );
  }
}

/// 描述 [MetroApp] 中 [Scrollable] 小部件的行为。
///
/// {@macro flutter.widgets.scrollBehavior}
///
/// 设置 [MaterialScrollBehavior] 将在
/// [TargetPlatform.android] 和 [TargetPlatform.fuchsia] 上执行时，向 [Scrollable] 的后代应用 [GlowingOverscrollIndicator]。
///
/// 在使用桌面平台时，如果 [Scrollable] 小部件在 [Axis.vertical] 上滚动，则会应用 [Scrollbar]。
///
/// 如果滚动方向是 [Axis.horizontal]，滚动视图的可发现性较低，因此在这些情况下考虑添加滚动条，可以直接添加或通过 [buildScrollbar] 方法添加。
///
/// [ThemeData.useMaterial3] 指定在 [TargetPlatform.android] 上使用的
/// overscroll indicator，默认为 true，导致使用 [StretchingOverscrollIndicator]。将
/// [ThemeData.useMaterial3] 设置为 false 则改为使用 [GlowingOverscrollIndicator]。
///
/// 另请参见：
///
///  * [ScrollBehavior]，此类扩展的默认滚动行为。
class MaterialScrollBehavior extends ScrollBehavior {
  /// 创建一个 MaterialScrollBehavior，该行为根据当前平台和提供的 [ScrollableDetails] 使用 [StretchingOverscrollIndicator] 和 [Scrollbar] 装饰 [Scrollable]。
  ///
  /// [ThemeData.useMaterial3] 指定在 [TargetPlatform.android] 上使用的 overscroll 指示器，默认为 true，这将导致使用 [StretchingOverscrollIndicator]。将 [ThemeData.useMaterial3] 设置为 false 将使用 [GlowingOverscrollIndicator]。
  const MaterialScrollBehavior();

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      Theme.of(context).platform;

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
        return child;
      case Axis.vertical:
        switch (getPlatform(context)) {
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            assert(details.controller != null);
            return Scrollbar(
              controller: details.controller,
              child: child,
            );
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
            return child;
        }
    }
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    final AndroidOverscrollIndicator indicator = Theme.of(context).useMaterial3
        ? AndroidOverscrollIndicator.stretch
        : AndroidOverscrollIndicator.glow;
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
      case TargetPlatform.android:
        switch (indicator) {
          case AndroidOverscrollIndicator.stretch:
            return StretchingOverscrollIndicator(
              axisDirection: details.direction,
              clipBehavior: details.clipBehavior ?? Clip.hardEdge,
              child: child,
            );
          case AndroidOverscrollIndicator.glow:
            break;
        }
      case TargetPlatform.fuchsia:
        break;
    }
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Theme.of(context).colorScheme.secondary,
      child: child,
    );
  }
}

class _MetroAppState extends State<MetroApp> {
  late HeroController _heroController;

  bool get _usesRouter =>
      widget.routerDelegate != null || widget.routerConfig != null;

  @override
  void initState() {
    super.initState();
    _heroController = MetroApp.createMaterialHeroController();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

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

  Widget _inspectorSelectButtonBuilder(
      BuildContext context, VoidCallback onPressed) {
    return FloatingActionButton(
      onPressed: onPressed,
      mini: true,
      child: const Icon(Icons.search),
    );
  }

  ThemeData _themeBuilder(BuildContext context) {
    ThemeData? theme;
    // Resolve which theme to use based on brightness and high contrast.
    final ThemeMode mode = widget.themeMode ?? ThemeMode.system;
    final Brightness platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final bool useDarkTheme = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == ui.Brightness.dark);
    final bool highContrast = MediaQuery.highContrastOf(context);
    if (useDarkTheme && highContrast && widget.highContrastDarkTheme != null) {
      theme = widget.highContrastDarkTheme;
    } else if (useDarkTheme && widget.darkTheme != null) {
      theme = widget.darkTheme;
    } else if (highContrast && widget.highContrastTheme != null) {
      theme = widget.highContrastTheme;
    }
    theme ??= widget.theme ?? ThemeData.light();
    return theme;
  }

  Widget _materialBuilder(BuildContext context, Widget? child) {
    final ThemeData theme = _themeBuilder(context);
    final Color effectiveSelectionColor =
        theme.textSelectionTheme.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
    final Color effectiveCursorColor =
        theme.textSelectionTheme.cursorColor ?? theme.colorScheme.primary;

    Widget childWidget = child ?? const SizedBox.shrink();

    if (widget.themeAnimationStyle != AnimationStyle.noAnimation) {
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
            return widget.builder!(context, child);
          },
        );
      }
      childWidget = AnimatedTheme(
        data: theme,
        duration: widget.themeAnimationStyle?.duration ??
            widget.themeAnimationDuration,
        curve: widget.themeAnimationStyle?.curve ?? widget.themeAnimationCurve,
        child: childWidget,
      );
    } else {
      childWidget = Theme(
        data: theme,
        child: childWidget,
      );
    }

    return MetroPageMessenger(
      key: widget.metroScaffoldMessengerKey,
      child: DefaultSelectionStyle(
        selectionColor: effectiveSelectionColor,
        cursorColor: effectiveCursorColor,
        child: childWidget,
      ),
    );
  }

  Widget _buildWidgetApp(BuildContext context) {
    // color 属性总是从浅色主题中获取，即使启用了深色模式。
    // 这样做是为了简化切换主题的技术细节，并且被认为是可接受的，
    // 因为这个 color 属性仅用于旧的 Android 操作系统中，
    // 用于在 Android 的切换器 UI 中着色应用栏。
    //
    // 蓝色是默认主题的主色。
    final Color materialColor =
        widget.color ?? widget.theme?.primaryColor ?? Colors.blue;
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
        textStyle: _errorTextStyle,
        color: materialColor,
        locale: widget.locale,
        localizationsDelegates: _localizationsDelegates,
        localeResolutionCallback: widget.localeResolutionCallback,
        localeListResolutionCallback: widget.localeListResolutionCallback,
        supportedLocales: widget.supportedLocales,
        showPerformanceOverlay: widget.showPerformanceOverlay,
        showSemanticsDebugger: widget.showSemanticsDebugger,
        debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
        inspectorSelectButtonBuilder: _inspectorSelectButtonBuilder,
        shortcuts: widget.shortcuts,
        actions: widget.actions,
        restorationScopeId: widget.restorationScopeId,
      );
    }

    return WidgetsApp(
      key: GlobalObjectKey(this),
      navigatorKey: widget.navigatorKey,
      navigatorObservers: widget.navigatorObservers!,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return MaterialPageRoute<T>(settings: settings, builder: builder);
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
      textStyle: _errorTextStyle,
      color: materialColor,
      locale: widget.locale,
      localizationsDelegates: _localizationsDelegates,
      localeResolutionCallback: widget.localeResolutionCallback,
      localeListResolutionCallback: widget.localeListResolutionCallback,
      supportedLocales: widget.supportedLocales,
      showPerformanceOverlay: widget.showPerformanceOverlay,
      showSemanticsDebugger: widget.showSemanticsDebugger,
      debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
      inspectorSelectButtonBuilder: _inspectorSelectButtonBuilder,
      shortcuts: widget.shortcuts,
      actions: widget.actions,
      restorationScopeId: widget.restorationScopeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result = _buildWidgetApp(context);
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

    return ScrollConfiguration(
      behavior: widget.scrollBehavior ?? const MaterialScrollBehavior(),
      child: HeroControllerScope(
        controller: _heroController,
        child: result,
      ),
    );
  }
}
