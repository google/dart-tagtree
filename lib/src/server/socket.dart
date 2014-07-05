part of server;

WebSocketRoot socketRoot(WebSocket socket, core.TagSet maker) =>
    new WebSocketRoot(socket, maker);

/// A WebSocketRoot runs a [Session] on a WebSocket.
class WebSocketRoot {
  final WebSocket _socket;
  final Codec<dynamic, String> _codec;
  Session _session;
  int nextFrameId = 0;
  _Frame _handleFrame, _nextFrame;
  bool renderScheduled = false;

  WebSocketRoot(this._socket, core.TagSet tags) :
      _codec = tags.makeCodec();

  /// Starts running a Session on this WebSocket.
  void mount(Session s) {
    assert(_session == null);
    _session = s;
    _session._mount(this);
    _socket.forEach((String data) {
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
    String encoded = _codec.encode(_session.render());
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
