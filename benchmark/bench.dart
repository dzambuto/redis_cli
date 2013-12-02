library bench;

import 'dart:async';

/*
 * Base Test class
 */

class Test {
  
  final String _name;
  final Stopwatch _watch = new Stopwatch();
  final Completer<double> _completer = new Completer();
  
  int _elapsed = 0;
  
  double get elapsed => _elapsed/1000;
  int get now => _watch.elapsedMilliseconds;
  int diff(start) => this.now - start;
  String get name => _name;
  
  Test(this._name);

  void run(Function done) {}
  
  void teardown(Function done) {}
  
  void setup(Function done) {}
  
  Future<double> report() {
    _measure();
    return _completer.future;
  }
  
  void stat() {
    print(_name + ',\telapsed ' + _elapsed.toString());
  }

  Future<double> _measure() {
    setup(_setupDone);
  }
  
  void _measureFor(Function f, int timeMinimum) {
    _watch.start();
    f(_done);
  }
  
  void _setupDone(err) {
    if(err != null && !_completer.isCompleted) return _completer.completeError(err);
    else  if(err == null) _measureFor(run, 100);
  }
  
  void _teardownDone(err) {
    if(err != null && !_completer.isCompleted) return _completer.completeError(err);
    else if(err == null) {
      stat();
      _completer.complete(_elapsed/1000);
    }
  }
  
  void _done(err) {
    if(err != null && !_completer.isCompleted) return _completer.completeError(err);
    else if(err == null) {
      _elapsed = _watch.elapsedMilliseconds;
      _watch.stop;
      teardown(_teardownDone);
    }
  }
}

/*
 * Histogram class
 */

class Histogram {
  num _min = null;
  num _max = null;
  num _sum = null;
  num _varianceM = null;
  num _varianceS = null;
  num _count = 0;
  
  Histogram();
  
  num get min => _min;
  num get max => _max;
  num get mean => (_count == 0 ? null : _varianceM);
  num get variance => (_count < 1 ? null : _varianceS/(_count - 1));
  
  void update(num value) {
    _count++;
    
    if(_max == null) _max = value;
    else _max = (value > _max ? value : _max);
    
    if(_min == null) _min = value;
    else _min = (value < _min ? value : _min);
    
    _sum = (_sum == null ? value : _sum + value);
    
    _updateVariance(value);
  }
  
  void _updateVariance(num value) {
    num oldVM = _varianceM;
    num oldVS = _varianceS;
    
    if (_count == 1) {
      _varianceM = value;
      _varianceS = 0;
    } else {
      _varianceM = oldVM + (value - oldVM) / _count;
      _varianceS = oldVS + (value - oldVM) * (value - _varianceM);
    }
  }
}