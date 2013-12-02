part of redis;


/*
 * [_RedisProtocolTransformer]
 */
class _RedisProtocolTransformer implements StreamTransformer, EventSink {
  EventSink _eventSink;
  RedisProtocolParser _parser;
  
  Stream bind(Stream stream) {
    return new Stream.eventTransformed(
        stream,
        (EventSink eventSink) {
          if (_eventSink != null) {
            throw new StateError("Redis transformer already used.");
          }
          _eventSink = eventSink;
          _parser = new RedisProtocolParser(_eventSink);
          return this;
        });
  }

  void addError(Object error, [StackTrace stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  void close() => _eventSink.close();
  
  void add(List<int> bytes) {
    _parser.process(bytes);
  }
}


/*
 * [_RedisProtocolConsumer]
 */
class _RedisProtocolConsumer extends Stream<List<String>> implements StreamConsumer<List<int>> { 
  final Socket _socket;
  StreamSubscription _socketSubscription;
  StreamController<List<String>> _controller;
  RedisProtocolParser _parser;
  
  _RedisProtocolConsumer(this._socket) {
    _controller = new StreamController<List<String>>(
        sync: true,
        onListen: () {
          _socketSubscription.resume();
        },
        onPause: () {
        },
        onResume: () {
        },
        onCancel: () {
          try {
            _socketSubscription.cancel();
          } catch (e) {
          }
        });
    _parser = new RedisProtocolParser(_controller);
    _socket.pipe(this);
  }
  
  StreamSubscription<List<String>> listen(void onData(List<String> event),
      {Function onError,
    void onDone(),
    bool cancelOnError}) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }
  
  
  Future<_RedisProtocolConsumer> addStream(Stream<List<int>> stream) {
    var completer = new Completer();
    _socketSubscription = stream.listen(
        _onData,
        onError: _onError,
        onDone: () {
          completer.complete(this);
        });
    _socketSubscription.pause();
    return completer.future;
  }

  Future<_RedisProtocolConsumer> close() {
    _onDone();
    return new Future.value(this);
  }
  
  void _onData(List<int> buffer) {
    _socketSubscription.pause();
    _parser.process(buffer);
    _socketSubscription.resume();
  }
  
  void _onDone() {
    _socketSubscription = null;
    _controller.close();
  }
  
  void _onError(e, [StackTrace stackTrace]) {
    _controller.addError(e, stackTrace);
  }
}


/*
 * [_RedisOutgoingTransformer]
 */
class _RedisOutgoingTransformer implements StreamTransformer, EventSink {
  EventSink _eventSink;
  
  Stream bind(Stream stream) {
    return new Stream.eventTransformed(
        stream,
        (EventSink eventSink) {
          if (_eventSink != null) {
            throw new StateError("Redis transformer already used");
          }
          _eventSink = eventSink;
            return this;
        });
  }
  
  void addError(Object error, [StackTrace stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }
  
  void close() {
    _eventSink.close();
  }
  
  void add(List<String> command) {
    var encoded = "*${command.length}\r\n";
    for(int i = 0; i < command.length; i++) {
      String el = command[i];
      encoded += (el == null) ? "" : "\$${el.length}\r\n$el\r\n";
    }
    _eventSink.add(encoded);
  }
}


/*
 * [_RedisConsumer]
 */
class _RedisConsumer implements StreamConsumer {
  final Socket _socket;
  final RedisClient _client;
  StreamController _controller;
  StreamSubscription _subscription;
  bool _closed = false;
  Completer _closeCompleter = new Completer();
  Completer _completer;
  
  _RedisConsumer(this._client, this._socket) {
    _controller = new StreamController(sync: true,
        onPause: _onPause,
        onResume: _onResume,
        onCancel: _onListen);
    var stream = _controller.stream
        .transform(new _RedisOutgoingTransformer())
        .transform(UTF8.encoder);
    _socket.addStream(stream)
        .then((_) {
          _done();
          _closeCompleter.complete(_client);
        }, onError: (error, StackTrace stackTrace) {
          _closed = true;
          _cancel();
          if (error is ArgumentError) {
            if (!_done(error, stackTrace)) {
              _closeCompleter.completeError(error, stackTrace);
            }
          } else {
            _done();
            _closeCompleter.complete(_client);
          }
        });
  }
  
  void _onListen() {
    if (_subscription != null) {
      _subscription.cancel();
    }
  }

  void _onPause() {
    if (_subscription != null) {
      _subscription.pause();
    }
  }

  void _onResume() {
    if (_subscription != null) {
      _subscription.resume();
    }
  }

  void _cancel() {
    if (_subscription != null) {
      var subscription = _subscription;
      _subscription = null;
      subscription.cancel();
    }
  }
  
  bool _done([error, StackTrace stackTrace]) {
    if (_completer == null) return false;
    if (error != null) {
      _completer.completeError(error, stackTrace);
    } else {
      _completer.complete(_client);
    }
    _completer = null;
    return true;
  }

  Future addStream(var stream) {
    if (_closed) {
      stream.listen(null).cancel();
      return new Future.value(_client);
    }
    _completer = new Completer();
    _subscription = stream.listen(
        (data) {
          _controller.add(data);
        },
        onDone: _done,
        onError: _done,
        cancelOnError: true);
    
    return _completer.future;
  }

  Future close() {
    Future closeSocket() {
      return _socket.close().catchError((_) {}).then((_) => _client);
    }
    _controller.close();
    return _closeCompleter.future.then((_) => closeSocket());
  }

  void add(data) {
    if (_closed) return;
    _controller.add(data);
  }
}


