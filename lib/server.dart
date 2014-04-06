/**
 * Glue code connecting the ViewTree core with the dart:io library.
 */
library server;

import 'package:viewtree/core.dart' as core;

import 'dart:io';

/// A view tree container that renders to a WebSocket.
class WebSocketRoot {
  final WebSocket _socket;
  final core.JsonRuleSet _ruleSet;

  WebSocketRoot(this._socket, {core.JsonRuleSet rules}) :
      _ruleSet = (rules == null) ? core.eltRules : rules;

  /// Replaces the view with a new version.
  ///
  /// Supports Html elements by default. Additional views may be supported by
  /// passing a JsonRuleSet in the contructor.
  void mount(core.Tag tagTree) {
    String encoded = _ruleSet.encodeTree(tagTree);
    _socket.add(encoded);
  }
}
