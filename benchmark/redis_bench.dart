import 'bench.dart';
import 'dart:async';
import '../lib/redis.dart';

class RedisTest extends Test {
  final List<RedisClient> _clients = new List();
  final Histogram _hist = new Histogram();
  
  int _numberOfClients;
  int _numberOfConn;
  int _pipeline;
  
  int _ops = 20000;
  int _completed = 0;
  int _sent = 0;
    
  RedisTest(String name, this._numberOfConn, this._pipeline) : super(name) {
    _numberOfClients = _numberOfConn;
  }
  
  Future op(RedisClient client) {}
  
  void stat() {
    String pipe = _pipeline.toString() + "/" + _numberOfClients.toString();
    String hist = '${rpad(_hist.min.toString(), 10)}/${rpad(_hist.max.toString(), 10)}/${rpad(_hist.mean.toStringAsFixed(2), 10)}';
    print('${rpad(name, 10)},\t${rpad(pipe, 10)},\t${rpad(hist, 10)}\t${rpad((elapsed*1000).floor().toString(), 10)}ms,\t' + rpad((_ops/elapsed).floor().toString(), 10) + ' ops/s');
  }
  
  void _next(Function done) {
    num pipe = _sent - _completed;
    while(_sent < _ops && pipe < _pipeline) {
      int start = this.now;
      _sent++;
      pipe++;
      op(_clients[_sent % _clients.length]).then((data) {
        _hist.update(this.diff(start));
        _completed++;
        _next(done);
      });
    }
    
    if(_completed == _ops) {
      done(null);
    }
  }
  
  void run(done) {
    _next(done);
  }
  
  void setup(done) {
     for(var i = 0; i < _numberOfConn; i++) {
       RedisClient.bind('127.0.0.1', 6379).then((client) {
         _clients.add(client);
         if(_clients.length == _numberOfConn) {
             done(null);
         }
       }).catchError((err) {
         print('Socket $err');
         done(err);
       });
     }
  }
  
  void teardown(done) {
    _clients.forEach((client) {
      client.close().then((socket) {
        if(--_numberOfConn == 0) done(null);
      });
    });
  }
  
  String rpad(String str, int max) {
    if(str.length >= max) return str;
    while(str.length < max) {
      str = " " + str;
    }
    return str;
  }
}


class RedisGetTest extends RedisTest{
  final String _key;
  
  RedisGetTest(String name, this._key, int n, int pipeline) : super(name, n, pipeline);
  Future op(RedisClient client) {
    return client.get(_key);
  }
}


class RedisIncrTest extends RedisTest{
  final String _key;
  
  RedisIncrTest(String name, this._key, int n, int pipeline) : super(name, n, pipeline);
  Future op(RedisClient client) {
    return client.incr(_key);
  }
}

class RedisSetTest extends RedisTest{
  final String _key;
  final String _value;
  
  RedisSetTest(String name, this._key, this._value, int n, int pipeline) : super(name, n, pipeline);
  Future op(RedisClient client) {
    return client.set(_key, _value);
  }
}

class RedisLpushTest extends RedisTest{
  final String _key;
  final List<String> _values;
  
  RedisLpushTest(String name, this._key, this._values, int n, int pipeline) : super(name, n, pipeline);
  Future op(RedisClient client) {
    return client.lpush(_key, _values);
  }
}

class RedisLrangeTest extends RedisTest{
  final String _key;
  final List<int> _values;
  
  RedisLrangeTest(String name, this._key, this._values, int n, int pipeline) : super(name, n, pipeline);
  Future op(RedisClient client) {
    return client.lrange(_key, _values);
  }
}

class RedisPingTest extends RedisTest{
  RedisPingTest(String name, int n, int pipeline) : super(name, n, pipeline);
  Future op(RedisClient client) {
    return client.ping();
  }
}

void main() {
  num n = 5;
  String value = '1234';
  var arr = new List(4097);
  arr.fillRange(0, 4097, '-');
  String bigValue = arr.toString();
  var test = new RedisPingTest('PING', n, 1);
  var times = [];
  
  test.report()
    .then((elapsed) => (new RedisPingTest('PING', n, 50)).report())
    .then((elapsed) => (new RedisPingTest('PING', n, 200)).report())
    .then((elapsed) => (new RedisPingTest('PING', n, 20000)).report())
    .then((elapsed) => (new RedisSetTest('SET small str', 'foo_rand000000000000', value, n, 1)).report())
    .then((elapsed) => (new RedisSetTest('SET small str', 'foo_rand000000000000', value, n, 50)).report())
    .then((elapsed) => (new RedisSetTest('SET small str', 'foo_rand000000000000', value, n, 200)).report())
    .then((elapsed) => (new RedisSetTest('SET small str', 'foo_rand000000000000', value, n, 20000)).report())
    .then((elapsed) => (new RedisGetTest('GET small str', 'foo_rand000000000000', n, 1)).report())
    .then((elapsed) => (new RedisGetTest('GET small str', 'foo_rand000000000000', n, 50)).report())
    .then((elapsed) => (new RedisGetTest('GET small str', 'foo_rand000000000000', n, 200)).report())
    .then((elapsed) => (new RedisGetTest('GET small str', 'foo_rand000000000000', n, 20000)).report())
    //.then((elapsed) => (new RedisSetTest('SET large str', 'foo_rand000000000000', bigValue, n, 1)).report())
    .then((elapsed) => (new RedisSetTest('SET large str', 'foo_rand000000000000', bigValue, n, 50)).report())
    .then((elapsed) => (new RedisSetTest('SET large str', 'foo_rand000000000000', bigValue, n, 200)).report())
    .then((elapsed) => (new RedisSetTest('SET large str', 'foo_rand000000000000', bigValue, n, 20000)).report())
    .then((elapsed) => (new RedisGetTest('GET large str', 'foo_rand000000000000', n, 1)).report())
    .then((elapsed) => (new RedisGetTest('GET large str', 'foo_rand000000000000', n, 50)).report())
    .then((elapsed) => (new RedisGetTest('GET large str', 'foo_rand000000000000', n, 200)).report())
    .then((elapsed) => (new RedisGetTest('GET large str', 'foo_rand000000000000', n, 20000)).report())
    .then((elapsed) => (new RedisIncrTest('INCR', 'counter_rand000000000000', n, 1)).report())
    .then((elapsed) => (new RedisIncrTest('INCR', 'counter_rand000000000000', n, 50)).report())
    .then((elapsed) => (new RedisIncrTest('INCR', 'counter_rand000000000000', n, 200)).report())
    .then((elapsed) => (new RedisIncrTest('INCR', 'counter_rand000000000000', n, 20000)).report())
    .then((elapsed) => (new RedisLpushTest('LPUSH', 'mylist', [value], n, 1)).report())
    .then((elapsed) => (new RedisLpushTest('LPUSH', 'mylist', [value], n, 50)).report())
    .then((elapsed) => (new RedisLpushTest('LPUSH', 'mylist', [value], n, 200)).report())
    .then((elapsed) => (new RedisLpushTest('LPUSH', 'mylist', [value], n, 20000)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 10', 'mylist', [0, 9], n, 1)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 10', 'mylist', [0, 9], n, 50)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 10', 'mylist', [0, 9], n, 200)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 10', 'mylist', [0, 9], n, 20000)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 100', 'mylist', [0, 99], n, 1)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 100', 'mylist', [0, 99], n, 50)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 100', 'mylist', [0, 99], n, 200)).report())
    .then((elapsed) => (new RedisLrangeTest('LRANGE 100', 'mylist', [0, 99], n, 20000)).report())
    .then((elapsed) => print('End of Test.'))
    .catchError((err) {
      print(err);
    });
}