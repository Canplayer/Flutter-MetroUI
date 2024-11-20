import 'package:flutter/widgets.dart';

//Windows Phone 核心风格组件磁贴，所有可以被按下的组件都遵照这个规范进行设计修改

class Tile extends StatefulWidget {
  //传入子组件
  final Widget? child;
  //是否允许回弹
  final bool allowBack;
  //按下后发生的事件
  final Function()? onTap;

  const Tile({super.key, this.child, this.allowBack = true, this.onTap});

  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final double _maxRotation = 10.0; // 最大旋转角度
  //final double _perspective = 0.001; //透视系数
  //bool _isAddPostFrame = false; //渲染完成回调
  final double _pressedElevation = 20; //当被按下Z轴下沉的距离数值
  final double _pi = 3.1416; //圆周率

  //是否按下
  bool _isTouch = false;
  //回弹时间（毫秒）
  final int _springTime = 400;

  double rotateX = 0.0;
  double rotateY = 0.0;
  double translateZ = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween(begin: 1.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {
          rotateX *= _animation.value;
          rotateY *= _animation.value;
          translateZ *= _animation.value;
        });
      });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   setState(() {
    //     _isAddPostFrame = true;
    //   });
    // });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //获取相对于屏幕中心的偏移量
  // Offset _getAbsolutePosition() {
  //   //获取当前组件的渲染对象的位置
  //   final RenderBox renderBox = context.findRenderObject() as RenderBox;
  //   final position = renderBox.localToGlobal(Offset.zero);
  //   //获取屏幕大小
  //   final screenSize = MediaQuery.of(context).size;
  //   //获取屏幕中心点
  //   final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
  //   //返回位置相比屏幕中心的偏移量
  //   return screenCenter - position;
  // }

  void _updateRotation(
      Offset localPosition, double cardWidth, double cardHeight) {
    final double offsetX =
        -(localPosition.dx - cardWidth / 2) / (cardWidth / 2);
    final double offsetY =
        (localPosition.dy - cardHeight / 2) / (cardHeight / 2);

    setState(() {
      rotateX = offsetX * _maxRotation * (_pi / 180); // 将度数转换为弧度
      rotateY = offsetY * _maxRotation * (_pi / 180); // 将度数转换为弧度
      translateZ = _pressedElevation;
    });
  }

  //与TapDown的区别：TapDown下系统会反应一小下才会触发，而PanDown是立即触发
  void _handlePanDown(
      DragDownDetails details, double cardWidth, double cardHeight) {
    //打断所有动画
    _controller.stop();
    _updateRotation(details.localPosition, cardWidth, cardHeight);
  }

  void _handlePanUpdate(
      DragUpdateDetails details, double cardWidth, double cardHeight) {
    final localPosition = details.localPosition;
    if (localPosition.dx >= 0 &&
        localPosition.dx <= cardWidth &&
        localPosition.dy >= 0 &&
        localPosition.dy <= cardHeight) {
      _updateRotation(localPosition, cardWidth, cardHeight);
    } else {
      _isTouch = false;
      _handleTapUp();
    }
  }

  //手指离开屏幕后，卡片回弹
  Future<void> _handleTapUp() async {
    //储存当前的touch状态
    final isTouch = _isTouch;
    await Future.delayed(Duration(milliseconds: _springTime));
    if (isTouch != _isTouch) return;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        return Transform(
          alignment: FractionalOffset.center,
          // origin: Offset(
          //     (_isAddPostFrame ? _getAbsolutePosition().dx : 0) - cardWidth / 2,
          //     (_isAddPostFrame ? _getAbsolutePosition().dy : 0) -
          //         cardHeight / 2),
          //origin: _isAddPostFrame ? _getAbsolutePosition() : null,
          transform: Matrix4.identity()
          //..setEntry(3, 2, _perspective) // 设置透视投影参数
          //..setEntry(0, 3, (_isAddPostFrame ? _getAbsolutePosition().dx : 0) - cardWidth / 2)
          //..setEntry(1, 3, (_isAddPostFrame ? _getAbsolutePosition().dy : 0) - cardHeight / 2)
          ,
          child: Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              //..setEntry(3, 2, _perspective) // 设置透视投影参数
              //移动到屏幕中心
              //..setEntry(0, 3, -((_isAddPostFrame ? _getAbsolutePosition().dx : 0) - cardWidth / 2))
              //..setEntry(1, 3, -((_isAddPostFrame ? _getAbsolutePosition().dy : 0) - cardHeight / 2))
              //..setEntry(2, 3, _isTap?_pressedElevation:0) // 设置Z轴偏移
              ..setEntry(2, 3, translateZ) // 设置Z轴偏移
              ..rotateX(rotateY) // 调整倾斜系数
              ..rotateY(rotateX), // 调整倾斜系数
            //按下缩小,

            child: GestureDetector(
              //触碰即按下
              onPanDown: (details) {
                _isTouch = true;
                _handlePanDown(details, cardWidth, cardHeight);
              },
              //手指移动触发
              onPanUpdate: (details) {
                if (_isTouch) _handlePanUpdate(details, cardWidth, cardHeight);
              },
              onTap: () async {
                //此处会被onPanCancel优先执行，但是动画会等待我们一段时间，在等待的时间内，如果_isTouch状态被改变，那么onPanCancel的动画就不会执行
                _isTouch = true;
                await widget.onTap?.call();
                _handleTapUp();
              },
              //移动操作离开屏幕（松手了）
              onPanEnd: (details) async {
                final localPosition = details.localPosition;
                if (_isTouch &&
                    (localPosition.dx >= 0 &&
                        localPosition.dx <= cardWidth &&
                        localPosition.dy >= 0 &&
                        localPosition.dy <= cardHeight)) {
                  await widget.onTap?.call();
                }
                _isTouch = false;
                _handleTapUp();
              },
              //移动取消（例如被打断、触发点击事件）
              onPanCancel: () async {
                if (_isTouch) {
                  _isTouch = false;
                  _handleTapUp();
                }
              },

              //按住移动一点点就判定
              // onTapCancel: () {
              //   print('onTapCancel');
              //   //_handleTapUp();
              // },

              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
