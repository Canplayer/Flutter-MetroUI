import 'package:flutter/material.dart';

void main() {
  final controller = AnimationController(vsync: const TestVSync(), duration: Duration(milliseconds: 250));
  print(controller.status);
  
  controller.addListener(() {
    print('value: ${controller.value}');
  });
  
  controller.animateTo(1.0, curve: Curves.easeOut, duration: Duration(milliseconds: 250));
  
  print(controller.status);
}

class TestVSync implements TickerProvider {
  const TestVSync();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
