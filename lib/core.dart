/**
 * This library includes all the shared code of the ViewTree framework.
 *
 * To display a View in a browser, you also need package:viewtree/browser.dart.
 * To create Views on the server, you also need package:viewtree/server.dart.
 */
library core;

import 'dart:async' show Stream, StreamController, StreamSink;
import 'dart:convert';

part 'src/core/customtag.dart';
part 'src/core/elt.dart';
part 'src/core/event.dart';
part 'src/core/frame.dart';
part 'src/core/inner.dart';
part 'src/core/json.dart';
part 'src/core/root.dart';
part 'src/core/state.dart';
part 'src/core/tags.dart';
part 'src/core/template.dart';
part 'src/core/text.dart';
part 'src/core/view.dart';
part 'src/core/widget.dart';
part 'src/core/tx/mount.dart';
part 'src/core/tx/transaction.dart';
part 'src/core/tx/unmount.dart';
part 'src/core/tx/update.dart';
