/**
 * Glue code connecting the ViewTree core with the dart:io library.
 */
library server;

import 'package:viewtree/core.dart' as core;

import 'dart:io';

abstract class ServerWidget extends core.View {
  ServerWidget() : super(null);

  @override
  core.Props get props => new core.Props({});

  core.View render();

  @override
  void doMount(StringBuffer out, core.Root _) {
    throw "not implemented";
  }

  @override
  void doUnmount(core.NextFrame frame) {
    throw "not implemented";
  }

  @override
  void traverse(callback(core.View v)) {
    throw "not implemented";
  }

  @override
  bool canUpdateTo(core.View nextVersion) => false;

  @override
  void update(core.View nextVersion, core.Transaction tx) {}
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
  void mount(core.View nextView) {
    while (!_canEncode(nextView)) {
      if (nextView is ServerWidget) {
        ServerWidget w = nextView;
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
