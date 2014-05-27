/**
 * Implements the API for working with tag trees in the browser.
 */
library browser;

import 'dart:async' show StreamSubscription;
import 'dart:collection' show HashMap;
import 'dart:html';

import 'package:tagtree/core.dart' as core;
import 'package:tagtree/html.dart' as html;
import 'package:tagtree/render.dart' as render;
import 'package:tagtree/widget.dart';

export 'package:tagtree/widget.dart';
export 'package:tagtree/html.dart';

part 'src/browser/dom.dart';
part 'src/browser/root.dart';
part 'src/browser/socket.dart';
part 'src/browser/tagset.dart';
