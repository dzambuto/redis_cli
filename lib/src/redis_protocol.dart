part of redis;

class IncompleteReadBuffer extends StateError {
  IncompleteReadBuffer(String msg) : super(msg);
}

class RedisProtocolParser {  
  final _controller;
  int _offset = 0;
  int _args = 1;
  List<int> _buffer;
  List<String> _reply;
  
  RedisProtocolParser(this._controller);
  
  void process(List<int> buffer) {
    int type, offset;
    String ret;
    
    _append(buffer);

    while(true) {
      offset = _offset;
      try {
        if(_bytesRemaining() < 4) {
          break;
        }
        
        type = _buffer[_offset++];
        
        if(type == 43 || type == 45 || type == 58 || type == 36) {
          ret = _parseResult(type);
          _add(ret);
        }
        else if(type == 42) {
          offset = _offset - 1;
          ret = _parseResult(type);
          if(ret == null) {
            _add(ret);
          }
        }
      }
      on IncompleteReadBuffer {
        _offset = offset;
        break;
      }
      catch(err) {
        print(err);
        throw err;
      }
    }   
  }
   
  String _parseResult(int type) {
    int start, end, offset, size;
    
    if(type == 43 || type == 45) {
      end = _packetEndOffset() - 1;
      start = _offset;
      
      _offset = end + 2;
      
      if(end > _buffer.length) {
        _offset = start;
        throw new IncompleteReadBuffer('Wait for more data');
      }
      
      return UTF8.decode(_buffer.sublist(start, end));
    }
    else if(type == 58) {
      end = _packetEndOffset() - 1;
      start = _offset;
      
      _offset = end + 2;
        
      if(end > _buffer.length) {
        _offset = start;
        throw new IncompleteReadBuffer('Wait for more data');
      }
      
      return UTF8.decode(_buffer.sublist(start, end));
    }
    else if(type == 36) {
      offset = _offset - 1;
      size = _parseHeader();
      
      if(size == -1) return null;
      
      end = _offset + size;
      start = _offset;
      
      _offset = end + 2;
      
      if(end > _buffer.length) {
        _offset = offset;
        throw new IncompleteReadBuffer('Wait for more data');
      }
      
      return UTF8.decode(_buffer.sublist(start, end));
    }
    else if(type == 42) {
      offset = _offset;
      size = _parseHeader();
      
      if(size < 0) return null;
      _args = size;
      return '';
    }
  }
  
  int _bytesRemaining() {
    return (_buffer.length - _offset) < 0 ? 0 : (_buffer.length - _offset);
  }
  
  int _parseHeader() {
    int end = _packetEndOffset();
    int value = int.parse(UTF8.decode(_buffer.sublist(_offset, end - 1)));

    this._offset = end + 1;

    return value;
  }
  
  int _packetEndOffset() {
    int offset = _offset;
    
    while(_buffer[offset] != 13 && _buffer[offset+1] != 10) {
      offset++;
      if(offset >= _buffer.length) throw new IncompleteReadBuffer("Wait for more data");
    }
    
    offset++;
    return offset;
  }
  
  void _add(String str) {
    if(_reply == null) _reply = new List(_args);
    _reply[_reply.length - _args] = str;
    if(--_args == 0) {
      _controller.add(_reply);
      _reply = null;
      _args = 1;
    }
  }
  
  void _append(List<int> buffer) {
    if(buffer == null) 
      return;
    
    if(_buffer == null) {
      _buffer = buffer;
      return;
    }
    
    if(_offset >= _buffer.length) {
      _buffer = buffer;
      _offset = 0;
      return;
    }
    
    List<int> tmp = _buffer.sublist(_offset);
    _buffer = new List<int>(tmp.length + buffer.length);
    _buffer.setRange(0, tmp.length, tmp);
    _buffer.setRange(tmp.length, _buffer.length, buffer);
    _offset = 0;
  }
}

/*
part of redis;

class RedisProtocolParser {
  final _controller;
  
  RedisProtocolParser(this._controller) {
    _state = _RedisProtocolState.START;
    _buffer = new List<int>();
  }
  
  void process(List<int> bytes) {
    _pivot = 0;
    _startPivot = 0;
    while(_pivot != bytes.length || _state == _RedisProtocolState.FINISH)
      _step(bytes);
  }
  
  void _step(List<int> bytes) {
    switch (_state) {
      case _RedisProtocolState.START:
        _start(bytes);
        break;
      case _RedisProtocolState.READING_NUM_OF_ARGS:
        _numberOfArgs(bytes);
        break;
      case _RedisProtocolState.READING_NUM_OF_BYTES_IN_ARG:
        _bytesInArg(bytes);
        break;
      case _RedisProtocolState.READING_ARG:
      case _RedisProtocolState.READING_INT:
        _arg(bytes);
        break;
      case _RedisProtocolState.READING_STATUS:
        _status(bytes);
        break;
      case _RedisProtocolState.FINISH:
        _finish();
        break;
    }
  }
  
  void _start(List<int> bytes) {
    int byte = bytes[_pivot++];
    _startPivot++;
    switch (byte) {
      case STAR_BYTE:
        _multi = true;
        _state = _RedisProtocolState.READING_NUM_OF_ARGS;
        break;
      case DOLLAR_BYTE:
        _state = _RedisProtocolState.READING_NUM_OF_BYTES_IN_ARG;
        break;
      case PLUS_BYTE:
      case MINUS_BYTE:
        _state = _RedisProtocolState.READING_STATUS;
        break;
      case COLON_BYTE:
        _state = _RedisProtocolState.READING_INT;
        break;
      default:
        break;
    }
    
    _buffer.length = 0;
  }
  
  void _numberOfArgs(List<int> bytes) {
    if(_line(bytes)) {
      _numOfArgs = _getInt();
      if(_numOfArgs == 0) {
        _reply = new List<String>();
        _state = _RedisProtocolState.FINISH;
      }
      else if(_numOfArgs == -1) _state = _RedisProtocolState.FINISH;
      else _state = _RedisProtocolState.START;
      _skip();
    }
  }
  
  void _bytesInArg(List<int> bytes) {
    if(_line(bytes)) {
      if(_isNull() && _multi) { 
        _cumulateNull();
        _state = _RedisProtocolState.START;
      }
      else if(_isNull() && !_multi) _state = _RedisProtocolState.FINISH;
      else _state = _RedisProtocolState.READING_ARG;
      _skip();
    }
  }
  
  void _arg(List<int> bytes) {
    if(_line(bytes)) {
      _cumulate();
      if(--_numOfArgs > 0) _state = _RedisProtocolState.START;
      else _state = _RedisProtocolState.FINISH;
    }
  }
  
  void _status(List<int> bytes) {
    if(_line(bytes)) {
      _cumulate();
      _state = _RedisProtocolState.FINISH;
    }
  }
  
  void _finish() {
    _controller.add(_reply);
    _reply = null;
    _multi = false;
    _buffer.length = 0;
    _numOfArgs = 1;
    _state = _RedisProtocolState.START;
  }
  
  bool _line(List<int> bytes) {
    int cr = bytes.indexOf(CR_BYTE, _pivot);
    
    if(cr == -1 || (cr + 1) == bytes.length) {
      if(_buffer.length == 0) _buffer = bytes.skip(_startPivot).take(bytes.length - _startPivot).toList(growable: true);
      else _buffer.addAll(bytes.skip(_startPivot).take(bytes.length - _startPivot));
      _pivot = bytes.length;
      return false;
    }

    if(bytes[cr + 1] != LF_BYTE) {
      _pivot += cr -_pivot + 1;
      return _line(bytes);
    }
    
    if(_buffer.length == 0) _buffer = bytes.skip(_startPivot).take(cr - _startPivot).toList(growable: true);
    else _buffer.addAll(bytes.skip(_startPivot).take(cr - _startPivot));
    _pivot += cr - _pivot + 2;
    _startPivot = _pivot;
    return true;
  }
  
  void _cumulate() {
    if (_reply == null) _reply = new List<String>();
    _reply.add(UTF8.decode(_buffer));
    _buffer.length = 0;
  }
  
  void _cumulateNull() {
    if (_reply == null) _reply = new List<String>();
    _reply.add(null);
  }
  
  void _skip() {
    _buffer.length = 0;
  }
  
  bool _isNull() {
    return _getInt() == -1;
  }
  
  int _getInt() {
    return int.parse(UTF8.decode(_buffer));
  }

  
  static const int CR_BYTE = 13;
  static const int LF_BYTE = 10;
  static const int STAR_BYTE = 42;
  static const int DOLLAR_BYTE = 36;
  static const int PLUS_BYTE = 43;
  static const int MINUS_BYTE = 45;
  static const int COLON_BYTE = 58;
  
  
  _RedisProtocolState _state;
  List<int> _buffer;
  bool _multi = false;
  int _numOfArgs = 1;
  int _pivot;
  int _startPivot;
  List<String> _reply;
}

class _RedisProtocolState {
  static const START = const _RedisProtocolState._(0);
  static const READING_NUM_OF_ARGS = const _RedisProtocolState._(1);
  static const READING_NUM_OF_BYTES_IN_ARG = const _RedisProtocolState._(2);
  static const READING_ARG = const _RedisProtocolState._(3);
  static const READING_INT = const _RedisProtocolState._(4);
  static const READING_STATUS = const _RedisProtocolState._(5);
  static const FINISH = const _RedisProtocolState._(6);
  
  
  static get values => [START, READING_NUM_OF_ARGS, READING_NUM_OF_BYTES_IN_ARG, READING_ARG, READING_INT, READING_STATUS, FINISH];

  final int value;

  const _RedisProtocolState._(this.value);
}
 */