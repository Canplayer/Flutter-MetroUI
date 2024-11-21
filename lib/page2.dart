//import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:metro_ui/merto/page_scaffold.dart';

class HelloWorldPage extends StatelessWidget {
  const HelloWorldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      body: Center(
        //放置背景图片
        child: Stack(
          children: [
            Image.asset(
              'assets/in.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            //放置文字
            Transform(
              origin: const Offset(-37.5, 0),
              transform: Matrix4.identity()..rotateY(-0.38),
              //让图片半透明
              child: Opacity(
                opacity: 0.5, // 设置透明度
                child: Image.asset(
                  'assets/1.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
