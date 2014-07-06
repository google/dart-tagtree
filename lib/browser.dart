/**
 * Renders tag trees to a web page in a browser.
 * (This is the only tagtree library that requires dart:html and cannot run on the server.)
 *
 * The [getRoot] method returns a [RenderRoot] for installing tag trees under a given HTML element.
 *
 * The [Ref] class is used to get a reference to the HTML element where an ElementTag was rendered.
 *
 * A [RemoteZone] can be used to display a stream of tag trees loaded from a WebSocket,
 * and send events back to the server.
 * (The server should use a WebSocketRoot for its end of the connection.)
 */
library browser;

import 'dart:async' show StreamSubscription;
import 'dart:collection' show HashMap;
import 'dart:html';

import 'package:tagtree/core.dart';
import 'package:tagtree/html.dart';
import 'package:tagtree/json.dart' show TaggedJsonCodec, Jsonable;
import 'package:tagtree/render.dart' as render;

export 'package:tagtree/html.dart';

part 'src/browser/dom.dart';
part 'src/browser/root.dart';
part 'src/browser/socket.dart';
