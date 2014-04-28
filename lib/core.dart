/**
 * This library includes the tag tree and basic types shared between client and server.
 *
 * To mount a tag tree in a browser, you also need package:viewtree/browser.dart.
 * To handle sessions on the server, you also need package:viewtree/server.dart.
 */
library core;

import 'dart:async' show Stream, StreamController, StreamSink;

part 'src/core/debug.dart';
part 'src/core/event.dart';
part 'src/core/html.dart';
part 'src/core/json.dart';
part 'src/core/state.dart';
part 'src/core/tagmaker.dart';
part 'src/core/tagtree.dart';
part 'src/core/widget.dart';
