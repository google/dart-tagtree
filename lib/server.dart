/**
 * Glue code connecting the ViewTree core with the dart:io library.
 */
library server;

import 'package:viewtree/core.dart' as core;

import 'dart:io';

abstract class ServerWidget extends core.Tag {
  ServerWidget() : super(null, null);

  core.Tag render();
}



/// A view tree container that renders to a WebSocket.
class WebSocketRoot {
  final WebSocket _socket;
  final core.JsonRuleSet _ruleSet;

  WebSocketRoot(this._socket, {core.JsonRuleSet rules}) :
      _ruleSet = (rules == null) ? core.Elt.rules : rules;

  /// Replaces the view with a new version.
  ///
  /// The previous view will be unmounted. Supports ServerWidget and Elts by default. Additional views
  /// may be supported by passing a JsonRuleSet in the contructor.
  void mount(core.Tag nextTag) {
    while (!_canEncode(nextTag)) {
      if (nextTag is ServerWidget) {
        ServerWidget w = nextTag;
        nextTag = w.render();
      } else {
        throw "can't encode view: ${nextTag.runtimeType}";
      }
    }
    String encoded = _ruleSet.encodeTree(nextTag);
    _socket.add(encoded);
  }

  bool _canEncode(v) => (v is core.Jsonable) && _ruleSet.supportsTag(v.jsonTag);
}
