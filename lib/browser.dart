/**
 * Renders tag trees to a web page in a browser.
 * This is the only tagtree library that requires dart:html.
 *
 * The [root] method returns a [RenderRoot] for installing tag trees under a given HTML element.
 *
 * The [Ref] class can be used to get a reference to the HTML element where a View was rendered.
 *
 * A [Slot] and its implementation, [SlotWidget], can be used to display a stream of tag trees
 * loaded from a WebSocket.
 */
library browser;

import 'dart:async' show StreamSubscription;
import 'dart:collection' show HashMap;
import 'dart:html';

import 'package:tagtree/core.dart';
import 'package:tagtree/html.dart';
import 'package:tagtree/json.dart' show TaggedJsonCodec;
import 'package:tagtree/render.dart' as render;
import 'package:tagtree/theme.dart';

export 'package:tagtree/theme.dart';
export 'package:tagtree/html.dart';

part 'src/browser/dom.dart';
part 'src/browser/root.dart';
part 'src/browser/socket.dart';
