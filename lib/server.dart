/**
 * Glue code connecting the ViewTree core with the dart:io library.
 */
library server;

import 'package:viewtree/core.dart' as core;

import 'dart:async' show scheduleMicrotask;
import 'dart:io';

WebSocketRoot socketRoot(WebSocket socket, {core.JsonRuleSet rules}) =>
    new WebSocketRoot(socket, rules);

/// A Session container that renders to a WebSocket.
class WebSocketRoot {
  final WebSocket _socket;
  final core.JsonRuleSet _ruleSet;
  Session _session;
  int nextFrameId = 0;
  _Frame _handleFrame, _nextFrame;
  bool renderScheduled = false;

  WebSocketRoot(this._socket, core.JsonRuleSet rules) :
      _ruleSet = (rules == null) ? core.eltRules : rules;

  /// Starts running a Session on this WebSocket.
  void mount(Session s) {
    assert(_session == null);
    _session = s;
    _session._mount(this);
    _socket.forEach((String data) {
      core.HandleCall call = _ruleSet.decodeTree(data);
      if (_handleFrame != null) {
        var func = _handleFrame.handlers[call.handle.id];
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
    _session.updateState();
    _nextFrame = new _Frame(nextFrameId++);
    String encoded = _ruleSet.encodeTree(_session.render());
    _socket.add(encoded);

    // TODO: possibly keep more than one frame in case of late callbacks
    // due to frame pipelining.
    _handleFrame = _nextFrame;
    _nextFrame = null;
  }
}

abstract class Session<S> extends core.StateMixin<S> {
  WebSocketRoot _root;

  _mount(root) {
    _root = root;
    initState();
  }

  @override
  invalidate() {
    _root._requestFrame();
  }

  core.Tag render();

  /// Wraps an event callback so that it can be sent over the WebSocket.
  /// This method may only be called during render.
  core.Handle remote(Function eventHandler) {
    return _root._nextFrame.createHandle(eventHandler);
  }
}

class _Frame {
  final int id;
  final Map handlers = <int, Function>{};
  int nextHandlerId = 0;

  _Frame(this.id);

  core.Handle createHandle(Function func) {
    var h = new core.Handle(id, nextHandlerId++);
    handlers[h.id] = func;
    return h;
  }
}
