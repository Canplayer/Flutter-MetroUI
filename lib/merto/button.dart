import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: Tile(
        child: widget.child,
        //onTap: widget.onTap,
      ),
    );
  }
}
