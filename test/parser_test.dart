import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'dart:convert';

import '../lib/redis.dart';

class MockController {
  void add(res) {
    //print(res);
  }
}

void main() {
  String str = createString(4097);
  List<int> cmd = command([str]), cmd1 = cmd.sublist(0, 1000), cmd2 = cmd.sublist(1001);
  List<int> big = command([str, str, str, str, str, str, str, str, str]);
  List<int> small = command([str, str, str, str, str, str, str, str, str]);
  RedisProtocolParser parser = new RedisProtocolParser(new MockController());
  
  useVMConfiguration();
  
  group('RedisProtocolParser', () {
    
    test('benchmark', () {
      Stopwatch watch = new Stopwatch();
      parser.process(cmd1);
      parser.process(cmd2);
      watch.start();
      for(int i = 0; i < 10; i++) {
        parser.process(cmd1);
        parser.process(cmd2);
      }
      print(watch.elapsedMicroseconds/10);
      watch.stop();
    });
    
    test('benchmark', () {
      Stopwatch watch = new Stopwatch();
      parser.process(cmd);
      watch.start();
      for(int i = 0; i < 10; i++) {
        parser.process(cmd);
      }
      print(watch.elapsedMicroseconds/10);
      watch.stop();
    });
    
  });
}

String createString(int length) {
  var arr = new List(length);
  arr.fillRange(0, length, '-');
  return arr.toString();
}

List<int> command(List<String> command) {
  var encoded = "";
  for(int i = 0; i < command.length; i++) {
    String el = command[i];
    encoded += (el == null) ? "" : "\$${el.length}\r\n$el\r\n";
  }
  return UTF8.encode(encoded);
}
