part of server;

/// A Session renders its UI remotely, via a web socket.
abstract class Session<S> extends core.StateMachineMixin<S> {
  WebSocketRoot _root;

  S getFirstState();

  _mount(root) {
    _root = root;
    initStateMachine(getFirstState());
  }

  @override
  invalidate() {
    _root._requestFrame();
  }

  core.Tag render();

  /// Wraps an event callback so that it can be sent over the WebSocket.
  /// This method may only be called during render.
  core.RemoteHandler remote(Function eventHandler) {
    return _root._nextFrame.createHandler(eventHandler);
  }
}
