part of redis;

class IncompleteReadBuffer extends StateError {
  IncompleteReadBuffer(String msg) : super(msg);
}

class RedisProtocolParserExp {  
  final _controller;
  int _offset = 0;
  int _args = 1;
  List<int> _buffer;
  List<String> _reply;
  
  RedisProtocolParserExp(this._controller);
  
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