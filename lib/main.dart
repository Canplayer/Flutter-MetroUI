import 'package:flutter/material.dart';
import 'package:metro_ui/tile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final List<GlobalKey> _keys = [];
  bool _isAddPostFrame = false; //渲染完成回调

  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<double> _edgeOffset;

  Map<String, IconData> iconMap = {
    'Phone': Icons.phone,
    'Email': Icons.email,
    'Map': Icons.map,
    'Camera': Icons.camera,
    'Calendar': Icons.calendar_today,
    'Clock': Icons.access_time,
    'Music': Icons.music_note,
    'People': Icons.people,
    'Weather': Icons.wb_sunny,
    'Store': Icons.store,
    'News': Icons.article,
    'Photos': Icons.photo,
    'Videos': Icons.video_collection,
    'Settings': Icons.settings,
    'Wallet': Icons.account_balance_wallet,
    'Calculator': Icons.calculate,
    'Alarms': Icons.alarm,
    'Notes': Icons.note,
    'Reminders': Icons.notifications,
    'Tasks': Icons.task,
    'Sports': Icons.sports_soccer,
    'Health': Icons.favorite,
  };

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(iconMap.length, (index) => GlobalKey()));

    _controllers = List.generate(iconMap.length, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 3.1416 / 2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInExpo,
      ));
    }).toList();

    _edgeOffset = List.generate(iconMap.length, (index) {
      return 0.0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isAddPostFrame = true;
      });
    });
  }

  void _startAnim() {
    for (int i = 0; i < _keys.length; i++) {
      final RenderBox renderBox =
          _keys[i].currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenSize = MediaQuery.of(context).size;
      // 过滤掉不在屏幕内的元素
      if (position.dx + size.width > 0 &&
          position.dx < screenSize.width &&
          position.dy + size.height > 0 &&
          position.dy < screenSize.height) {
        //print('子组件 $i 的绝对位置: $position');
      }
    }
  }

  //sync方法
  Future<void> _startAnimations(GlobalKey tapKey) async {
    _edgeOffset = List.generate(iconMap.length, (index) {
      return _getAbsolutePosition(_keys[index]).dx;
    });

    int thisIndex = 0;

    for (int i = 0; i < _keys.length; i++) {
      final RenderBox renderBox =
          _keys[i].currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenSize = MediaQuery.of(context).size;
      // 过滤掉不在屏幕内的元素
      if (position.dx + size.width > 0 &&
          position.dx < screenSize.width &&
          position.dy + size.height > 0 &&
          position.dy < screenSize.height) {
        if (_keys[i] == tapKey) {
          thisIndex = i;
          continue;
        }
        _controllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }

    _controllers[thisIndex].forward();


    // for (var controller in _controllers) {
    //   await Future.delayed(const Duration(milliseconds: 80));
    //   controller.forward();
    // }
    //播放完动画后，重置动画
    await Future.delayed(const Duration(milliseconds: 1000));
    for (var controller in _controllers) {
      controller.reset();
    }
  }

  //获取相对于屏幕左中心的偏移量
  Offset _getAbsolutePosition(GlobalKey key) {
    print("调用记录");
    //获取当前组件的渲染对象的位置
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    //获取屏幕大小
    final screenSize = MediaQuery.of(context).size;
    //获取屏幕左侧中心点
    final screenCenter = Offset(0, screenSize.height / 2);
    //返回位置相比屏幕中心的偏移量
    //return screenCenter - position;

    return Offset(-position.dx, position.dy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(0, 0, 0, 0),
      // appBar: AppBar(
      //   // TRY THIS: Try changing the color here to a specific color (to
      //   // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
      //   // change color while the other colors stay the same.
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   // Here we take the value from the MyHomePage object that was created by
      //   // the App.build method, and use it to set our appbar title.
      //   title: Text(widget.title),
      // ),
      body: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()..setEntry(3, 2, 0.001) // 设置Z轴偏移
        ,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 80),
          clipBehavior: Clip.none,
          child: Center(
            //padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 15,
              runSpacing: 15,
              clipBehavior: Clip.none,
              children: iconMap.keys.map((String key) {
                int index = iconMap.keys.toList().indexOf(key);
                return AnimatedBuilder(
                  animation: _animations[index],
                  builder: (context, child) {
                    return Transform(
                      origin: Offset(_edgeOffset[index], 0),
                      transform: Matrix4.identity()
                        ..rotateY(_animations[index].value),
                      child: SizedBox(
                        key: _keys[index],
                        width: 200,
                        height: 200,
                        child: Tile(
                          allowBack: true,
                          onTap: () async {
                            //等待两秒
                            await _startAnimations(_keys[index]);
                          },
                          child: Container(
                            color: const Color(0xFF2196F3),
                            child:
                                //分层布局
                                Stack(
                              children: [
                                //图标：居中
                                Center(
                                  child: Icon(
                                    iconMap[key],
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                ),
                                //文字：左下角
                                Positioned(
                                  left: 10,
                                  bottom: 10,
                                  child: Text(
                                    key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
