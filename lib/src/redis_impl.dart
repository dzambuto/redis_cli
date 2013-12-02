part of redis;

abstract class RedisClient {
  static Future<RedisClient> bind(String host, int port) => _RedisClient.connect(host, port);
  
  /*
   * String commands
   */
  Future<String> get(String key);
  Future<List> mget(List<String> keys);
  Future<bool> set(String key, String value);
  Future<bool> mset(List<String> keys);
  Future<int> append(String key, String value);
  Future incr(String key);
  Future<int> decr(String key);
  
  /*
   * Key commands
   */
  Future<int> del(String key);
  Future<String> dump(String key);
  Future<int> exists(String key);
  Future<int> expire(String key, int t);
  
  /*
   * List commands
   */
  Future<int> lpush(String key, List<String> values);
  Future<int> rpush(String key, List<String> values);
  Future<List> lrange(String key, List<int> index);
  Future<String> lpop(String key);
  Future<String> rpop(String key);
  
  Future<String> ping();
  
  Future close();
}

class _RedisClient implements RedisClient {
  static int _connection = 0;
  
  final Socket _socket;
  final int _connectionId = _connection++;
  StreamSink _sink;
  _RedisConsumer _consumer;
  _RedisProtocolConsumer _incoming;
  
  bool _connected = false;
  bool _closing = false;
  
  double retryMaxDelay = 0.0;
  int retryMaxAttempts = 10;
  int retryAttempts = 0;
  Timer retryTimer = null;
  
  _RedisCommandHandler _handler;

  static Future<RedisClient> connect(String host, int port) {
    Completer<_RedisClient> completer = new Completer();

    Socket.connect(host, port)
      .then((Socket socket) {
        completer.complete(new _RedisClient(socket));
      })
      .catchError((err) {
        print('Socket error: $err');
        completer.completeError(err);
      });
    
    return completer.future;
  }
  
  _RedisClient(this._socket) {
    _incoming = new _RedisProtocolConsumer(_socket);
    _incoming.listen(_onData, onError: _onError, onDone: _onDone);
    _consumer = new _RedisConsumer(this, _socket);
    _sink = new IOSink(_consumer);
    _handler = new _RedisCommandHandler(_sink);
  }

  _RedisCommandResponse command(List<String> command, [int bulks = 1]) {
    _handler.request(command);
    return _handler.enqueue(bulks);
  }
  
  Future<String> get(String key) => command(['GET', key]).getString();
  Future<bool> set(String key, String value) => command(['SET', key, value]).getState();
  Future<int> append(String key, String value) => command(['APPEND', key, value]).getInt();
  Future<int> incr(String key) => command(['INCR', key]).getInt();
  Future<int> decr(String key) => command(['DECR', key]).getInt();
  
  Future<List> mget(List<String> keys) {
    var args = ['MGET'];
    args.addAll(keys);
    return command(args).getList();
  }
  
  Future<bool> mset(List<String> keys) {
    var args = ['MSET'];
    args.addAll(keys);
    return command(args).getState();
  }
  
  Future<String> ping() => command(['PING']).getString();
  
  Future<int> del(String key) => command(['DEL', key]).getInt();
  Future<String> dump(String key) => command(['DUMP', key]).getString();
  Future<int> exists(String key) => command(['EXISTS', key]).getInt();
  Future<int> expire(String key, int t) => command(['EXPIRE', key, t.toString()]).getInt();
  Future<int> expireAt(String key, int t) => command(['EXPIREAT', key, t.toString()]).getInt();
  
  
  Future<String> lpop(String key) => command(['LPOP', key]).getString();
  
  Future<int> lpush(String key, List<String> values) {
    var args = ['LPUSH', key];
    args.addAll(values.reversed);
    return command(args).getInt();
  }
  
  Future<String> rpop(String key) => command(['RPOP', key]).getString();
  
  Future<int> rpush(String key, List<String> values) {
    var args = ['RPUSH', key];
    args.addAll(values.reversed);
    return command(args).getInt();
  }
  
  Future<List> lrange(String key, List<int> index) {
    var args = ['LRANGE', key];
    args.addAll(index.map((el) => el.toString()));
    return command(args).getList();
  }
  
  Future close() {
    _closing = true;
    return _sink.close();
  }
  
  void _reconnect() {
    
  }
  
  void _onData(List<String> data) {
    _handler.response(data);
  }
  
  void _onError(Object err) {
    print("Socket error: $err");
    // Reconnect
  }
  
  void _onDone() {
    if(_closing) {
      _handler = null;
      _socket.destroy();
    } else {
      _reconnect();
    }
  }
}