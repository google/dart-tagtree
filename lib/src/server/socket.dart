part of server;

typedef core.Animator MakeAnimatorFunc(core.JsonTag tag);

WebSocketRoot socketRoot(WebSocket socket, core.TagSet maker, MakeAnimatorFunc makeAnim) =>
    new WebSocketRoot(socket, maker, makeAnim);

/// A WebSocketRoot runs a Animator on a WebSocket.
class WebSocketRoot {
  final WebSocket _socket;
  final Stream incoming;
  final Codec<dynamic, String> _codec;
  final MakeAnimatorFunc makeAnim;

  core.JsonTag _request;
  core.Animator _anim;
  core.Place _place;

  int nextFrameId = 0;
  _Frame _handleFrame, _nextFrame;
  bool renderScheduled = false;

  WebSocketRoot(WebSocket socket, core.TagSet tags, this.makeAnim) :
    _socket = socket,
    incoming = socket.asBroadcastStream(),
    _codec = tags.makeCodec();

  /// Reads a request from the socket and starts the appropriate session.
  void start() {
    incoming.first.then((data) {
      core.JsonTag request = _codec.decode(data);
      var anim = makeAnim(request);
      if (anim == null) {
        print("ignored request: " + request.jsonTag);
        _socket.close();
      }
      _mount(anim, request);
    });
  }

  /// Starts running a Session on this WebSocket.
  void _mount(core.Animator anim, core.JsonTag request) {
    assert(_anim == null);
    _anim = anim;
    _request = request;

    _place = _anim.start(request);
    _place.delegate = new _PlaceDelegate(this);

    incoming.forEach((String data) {
      core.RemoteCallback call = _codec.decode(data);
      if (_handleFrame != null) {
        var func = _handleFrame.handlers[call.handler.id];
        if (func != null) {
          func(call.event);
        } else {
          print("ignored callback (no handler): ${data}");
        }
      } else {
        print("ignored callback (no frame): ${data}");
      }
    }).then((_) {
      _unmount();
    });

    _requestFrame();
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
    _nextFrame = new _Frame(nextFrameId++);
    String encoded = _codec.encode(_anim.renderAt(_place, _request));
    _socket.add(encoded);

    // TODO: possibly keep more than one frame in case of late callbacks
    // due to frame pipelining.
    _handleFrame = _nextFrame;
    _nextFrame = null;
  }
}

class _PlaceDelegate extends core.PlaceDelegate {
  WebSocketRoot root;
  _PlaceDelegate(this.root);

  @override
  void requestFrame() {
    root._requestFrame();
  }

  @override
  core.HandlerFunc wrapHandler(core.HandlerFunc h) {
    return root._nextFrame.createHandler(h);
  }
}

class _Frame {
  final int id;
  final Map handlers = <int, core.HandlerFunc>{};
  int nextHandlerId = 0;

  _Frame(this.id);

  core.RemoteHandler createHandler(core.HandlerFunc func) {
    var h = new core.RemoteHandler(id, nextHandlerId++);
    handlers[h.id] = func;
    return h;
  }
}
