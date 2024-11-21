import 'package:flutter/material.dart';
import 'package:metro_ui/merto/tile.dart';

//Windows Phone 核心风格的按钮设计组件

class MetroButton extends StatefulWidget {
  //传入子组件
  final Widget? child;
  //按下后发生的事件
  final Function()? onTap;

  const MetroButton({super.key, this.child, this.onTap});

  @override
  MetroButtoState createState() => MetroButtoState();
}

class MetroButtoState extends State<MetroButton> {
  @override
  Widget build(BuildContext context) {
    // return ConstrainedBox(
    //   constraints: const BoxConstraints(
    //     minWidth: 10,
    //     minHeight: 10,
    //   ),
    //   child: Container(
    //     decoration: BoxDecoration(
    //       //color: Colors.red, // 填充颜色
    //       border: Border.all(
    //         color: Colors.white, // 边框颜色
    //         width: 4.0, // 边框宽度
    //       ),
    //     ),
    //     child: LayoutBuilder(
    //       builder: (context, constraints) {
    //         return Transform(
    //           transform: Matrix4.identity(),
    //           child: const Text("1231231235555555555555",
    //               style: TextStyle(fontSize: 20.0, color: Colors.white)),
    //         );
    //       },
    //     ),
    //   ),
    //   //onTap: widget.onTap,
    // );

    return Tile(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          //color: Colors.red, // 填充颜色
          border: Border.all(
            color: Colors.white, // 边框颜色
            width: 4.0, // 边框宽度
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
