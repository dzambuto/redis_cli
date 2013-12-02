import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'dart:async';
import 'dart:math';
import 'dart:core';
import '../lib/redis.dart';

void main() {
  RedisClient client;
  String rnd = (new Random((new DateTime.now()).millisecondsSinceEpoch)).nextInt(9999).toString();
  var arr = new List(4097);
  arr.fillRange(0, 4097, '-');
  String bigValue = arr.toString();
  
  useVMConfiguration();

  group('list commands:', () {
    setUp(() {
      return RedisClient.bind('127.0.0.1', 6379).then((redis) {
        expect(redis, isNotNull);
        client = redis;
      });
    });
    
    test('LPUSH should return an Integer', () {
      Future future = client.lpush('list' + rnd, ['1', '2', '3', '4']);
      expect(future, completion(equals(4)));
    });

    test('LRANGE should return a List', () {
      Future future = client.lrange('list' + rnd, [0, -1]);
      expect(future, completion(equals(['1', '2', '3', '4'])));
    });
  });
  
  group('string commands:', () {    
    test('SET should return a Boolean', () {
      Future future = client.set('first' + rnd, 'miao');
      expect(future, completion(equals(true)));
    });
    
    test('MSET should return a Boolean', () {
      Future future = client.mset(['third' + rnd, 'third', 'fourth' + rnd, 'fourth']);
      expect(future, completion(equals(true)));
    });
    
    test('GET should return a String', () {
      Future future = client.get('first'+ rnd);
      expect(future, completion(equals('miao')));
    });
    
    test('GET should return \'null\' when key does not exist', () {
      Future future = client.get('notexists');
      expect(future, completion(equals(null)));
    });
    
    /*test('MGET should return a List', () {
      Future future = client.mget(['first'+ rnd, 'notexists']);
      expect(future, completion(orderedEquals(['miao', null])));
    });*/
    
    test('APPEND should return Integer', () {
      Future future = client.append('second' + rnd, 'miao');
      expect(future, completion(equals(4)));
    });
    
    test('INCR should return Integer', () {
      Future future = client.incr('counter' + rnd);
      expect(future, completion(equals(1)));
    });
    
    test('DECR should return Integer', () {
      Future future = client.decr('counter' + rnd);
      expect(future, completion(equals(0)));
    });
    
    test('DECR should return an Error', () {
      return client.decr('first' + rnd)
          .catchError((err) {
            expect(err, new isInstanceOf<StateError>());
            expect(err.message, equals('ERR value is not an integer or out of range'));
          });
    });
  });

  group('key commands:', () {
    test('DEL should return an Integer', () {
      Future future = client.del('first' + rnd);
      expect(future, completion(equals(1)));
    });
  });
  
  tearDown(() {
    return client.close().then((socket) {
      client = null;
    });
  });
}