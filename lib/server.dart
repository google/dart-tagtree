/**
 * Glue code connecting the ViewTree core with the dart:io library.
 */
library server;

import 'package:viewtree/core.dart' as core;

import 'dart:io';

/// A view container that renders to a WebSocket.
class WebSocketViewSink {
  final WebSocket _socket;
  final core.JsonRuleSet _ruleSet;

  WebSocketViewSink(this._socket, {core.JsonRuleSet rules}) :
      _ruleSet = (rules == null) ? core.Elt.rules : rules;

  /// Replaces the view with a new version.
  ///
  /// Views that are supported by the ruleSet will be sent over the wire (including their children).
  /// Widgets that cannot be sent over the wire will be rendered (recursively) until a
  /// View is found that can be sent.
  void mount(core.View nextView) {
    while (!_canEncode(nextView)) {
      if (nextView is core.Widget) {
        core.Widget w = nextView;
        nextView = w.render();
      } else {
        throw "can't encode view: ${nextView.runtimeType}";
      }
    }
    String encoded = _ruleSet.encodeTree(nextView);
    _socket.add(encoded);
  }

  bool _canEncode(v) => (v is core.Jsonable) && _ruleSet.supportsTag(v.jsonTag);
}
