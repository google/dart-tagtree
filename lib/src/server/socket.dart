part of server;

typedef core.Animator MakeAnimatorFunc(Jsonable request);

WebSocketRoot socketRoot(WebSocket socket, core.TagSet maker, MakeAnimatorFunc makeAnim) =>
    new WebSocketRoot(socket, maker, makeAnim);

/// A WebSocketRoot runs a Animator on a WebSocket.
class WebSocketRoot {
  final WebSocket _socket;
  final Stream incoming;
  final MakeAnimatorFunc makeAnim;

  Codec<dynamic, String> _codec;
  Jsonable _request;
  core.Animator _anim;
  core.Place _place;

  int nextFrameId = 0;
  _FrameFunctions _receivingFrame, _nextFrame;
  bool renderScheduled = false;

  WebSocketRoot(WebSocket socket, core.TagSet tags, this.makeAnim) :
    _socket = socket,
    incoming = socket.asBroadcastStream() {

    register(Function f) => _nextFrame.registerFunction(f);

    _codec = tags.makeCodec(register: register);
  }

  /// Reads a request from the socket and starts the appropriate session.
  void start() {
    incoming.first.then((data) {

      Jsonable request;
      try {
         request = _codec.decode(data);
      } on UnknownTagException catch (e) {
        print("ignored request (unknown tag): ${e.tag}");
        return;
      }

      var anim = makeAnim(request);
      if (anim == null) {
        print("ignored request (no animator): " + request.jsonType.tagName);
        _socket.close();
        return;
      }

      _mount(anim, request);
    });
  }

  /// Starts running a Session on this WebSocket.
  void _mount(core.Animator anim, Jsonable request) {
    assert(_anim == null);
    _anim = anim;
    _request = request;

    _place = _anim.start(request);
    _place.delegate = new _PlaceDelegate(this);

    incoming.forEach(_onMessage).then((_) => _unmount());

    _requestFrame();
  }

  void _onMessage(String data) {
    FunctionCall call;
    try {
      call = _codec.decode(data);
    } on UnknownTagException catch(e) {
      print("ignored remote function call (unknown tag): ${e.tag}");
    }

    if (_receivingFrame == null) {
      print("ignored remote function call (frame not available): ${data}");
      return;
    }

    var func = _receivingFrame.functions[call.key.id];
    if (func == null) {
      print("ignored remote function call (not in frame): ${data}");
      return;
    }

    Function.apply(func, call.args);
  }

  void _unmount() {
    if (_place.onCut != null) {
      _place.onCut(_place);
    }
    _place.delegate = null;
  }

  _requestFrame() {
    if (!renderScheduled) {
      renderScheduled = true;
      // TODO: render less often (limit frames/second)
      scheduleMicrotask(_render);
    }
  }

  _render() {
    renderScheduled = false;
    _place.commitState();

    _nextFrame = new _FrameFunctions(nextFrameId++);

    String encoded = _codec.encode(_anim.renderAt(_place, _request));
    _socket.add(encoded);

    _receivingFrame = _nextFrame;
    _nextFrame = null;

    // TODO: possibly keep more than one frame in case of late callbacks
    // due to frame pipelining.
  }
}

class _PlaceDelegate extends core.PlaceDelegate {
  WebSocketRoot root;
  _PlaceDelegate(this.root);

  @override
  void requestFrame() {
    root._requestFrame();
  }
}

class _FrameFunctions {
  final int id;
  final Map functions = <int, Function>{};
  int nextFunctionId = 0;

  _FrameFunctions(this.id);

  FunctionKey registerFunction(Function f) {
    var key = new FunctionKey(id, nextFunctionId++);
    functions[key.id] = f;
    return key;
  }
}
