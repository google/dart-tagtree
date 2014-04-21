/// Renders a tag tree to the DOM.
///
/// This library implements the algorithm for efficiently updating the DOM
/// whenever a tag tree changes. It doesn't have a direct dependency
/// on dart:html and so can run on either client or server, for testing.
///
/// To use it, you must subclass Root and provide an implementation of DomUpdater.
/// See the browser library for a complete implementation.
library render;

import 'package:viewtree/core.dart';

import 'dart:async' show EventSink;
import 'dart:convert';

part 'src/render/dom.dart';
part 'src/render/event.dart';
part "src/render/root.dart";
part 'src/render/viewtree.dart';
part 'src/render/tx/mount.dart';
part 'src/render/tx/transaction.dart';
part 'src/render/tx/unmount.dart';
part 'src/render/tx/update.dart';
