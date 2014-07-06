part of server;

typedef Session MakeSessionFunc(core.JsonTag tag);

WebSocketRoot socketRoot(WebSocket socket, core.TagSet maker, MakeSessionFunc makeSession) =>
    new WebSocketRoot(socket, maker, makeSession);

/// A WebSocketRoot runs a [Session] on a WebSocket.
class WebSocketRoot {
  final WebSocket _socket;
  final Stream incoming;
  final Codec<dynamic, String> _codec;
  final MakeSessionFunc makeSession;
  core.JsonTag _request;
  Session _session;
  int nextFrameId = 0;
  _Frame _handleFrame, _nextFrame;
  bool renderScheduled = false;

  WebSocketRoot(WebSocket socket, core.TagSet tags, this.makeSession) :
    _socket = socket,
    incoming = socket.asBroadcastStream(),
    _codec = tags.makeCodec();

  /// Reads a request from the socket and starts the appropriate session.
  void start() {
    incoming.first.then((data) {
      core.JsonTag request = _codec.decode(data);
      var session = makeSession(request);
      if (session == null) {
        print("ignored request: " + request.jsonTag);
        _socket.close();
      }
      mount(session, request);
    });
  }

  /// Starts running a different Session on this WebSocket.
  void mount(Session s, core.JsonTag request) {
    assert(_session == null);
    _session = s;
    _session._mount(this, request);
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
    });
    _requestFrame();
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
    _session.commitState();
    _nextFrame = new _Frame(nextFrameId++);
    String encoded = _codec.encode(_session.render(_request));
    _socket.add(encoded);

    // TODO: possibly keep more than one frame in case of late callbacks
    // due to frame pipelining.
    _handleFrame = _nextFrame;
    _nextFrame = null;
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
