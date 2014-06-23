part of server;

/// A Session renders its UI remotely, via a web socket.
abstract class Session<S> extends StateMachineMixin<S> {
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

  core.View render();

  /// Wraps an event callback so that it can be sent over the WebSocket.
  /// This method may only be called during render.
  core.HandlerId remote(Function eventHandler) {
    return _root._nextFrame.createHandler(eventHandler);
  }
}
