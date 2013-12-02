part of redis;

class _RedisCommandHandler{
  final StreamSink _sink;
  final Queue<_RedisCommandResponse> _queue;
  _RedisCommandResponse _current = null;
  
  _RedisCommandHandler(this._sink): _queue = new Queue<_RedisCommandResponse>();
    
  void request(List<String> command) {
    _sink.add(command);
  }
  
  _RedisCommandResponse enqueue(int numberOfBulk) {
    var response = new _RedisCommandResponse(numberOfBulk);
    _queue.add(response);
    return response;
  }
  
  void response(List<String> data) {
    if(_current == null) _current = _queue.removeFirst();
    if(_current.add(data)) _current = null;
  }
}

class _RedisCommandResponse {
  List _replies;
  Completer _completer = null;
  Function _convert = null;
  int _numberOfBulk;
  
  _RedisCommandResponse(this._numberOfBulk): 
    _replies = new List();
  
  bool add(List<String> reply) {
    if(_convert == null) {
      _replies.addAll(reply);
      if(--_numberOfBulk != 0) return false; 
      _completer.complete(_replies);
    }
    else {
      if(!_checkError(reply != null ? reply[0] : null))
        _convert(reply);
    }
    
    return true;
  }
  
  Future<bool> getState() {
    _completer = new Completer<bool>();
    _convert = _toState;
    return _completer.future;
  }
  
  Future<int> getInt() {
    _completer = new Completer<int>();
    _convert = _toInt;
    return _completer.future;
  }
  
  Future<String> getString() {
    _completer = new Completer<String>();
    _convert = _toString;
    return _completer.future;
  }
  
  Future<List> getList() {
    _completer = new Completer<List>();
    _convert = null;
    return _completer.future;
  }
  
  bool _checkError(String reply) {
    if(reply != null && reply.length > 3 && reply.substring(0, 3) == 'ERR') {
      _completer.completeError(new StateError(reply));
      return true;
    }
    return false;
  }
  
  void _toState(List<String> reply) {
    if(reply == null || reply.length == 0) _completer.complete(null);
    else if(reply[0] == 'OK') _completer.complete(true);
    else _completer.completeError(new StateError(reply[0]));
  }
  
  void _toString(List<String> reply) {
    if(reply == null || reply.length == 0) _completer.complete(null);
    else _completer.complete(reply.reduce((val, el) => val + el));
  }
  
  void _toInt(List<String> reply) {
    if(reply == null || reply.length == 0) _completer.complete(null);
    else {
      try {
        _completer.complete(int.parse(reply[0]));
      } catch(error) {
        _completer.completeError(error);
      }
    }
  }
}