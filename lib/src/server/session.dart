part of server;

/// A Session renders its UI remotely, via a web socket.
abstract class Session<R extends core.JsonTag, S> extends core.StateMachineMixin<S> {
  WebSocketRoot _root;

  S getFirstState(R request);

  _mount(root, R request) {
    _root = root;
    initStateMachine(getFirstState(request));
  }

  @override
  invalidate() {
    _root._requestFrame();
  }

  core.Tag render(R request);

  /// Wraps an event callback so that it can be sent over the WebSocket.
  /// This method may only be called during render.
  core.RemoteHandler remote(Function eventHandler) {
    return _root._nextFrame.createHandler(eventHandler);
  }
}
