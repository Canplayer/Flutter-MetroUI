import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: TestApp()));

class TestApp extends StatefulWidget {
  @override
  _TestAppState createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  
  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("Tapped. Value: ${ctrl.value}, status: ${ctrl.status}");
        if (ctrl.status == AnimationStatus.dismissed) {
          ctrl.animateTo(1.0, curve: Curves.bounceOut, duration: Duration(milliseconds: 1000));
        } else {
          ctrl.animateTo(0.0, curve: Curves.easeIn, duration: Duration(milliseconds: 1000));
        }
      },
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (c, _) => Container(
          color: Colors.red,
          height: 100 + 100 * ctrl.value,
          child: Center(child: Text("Height: ${100 + 100 * ctrl.value}")),
        ),
      ),
    );
  }
}
