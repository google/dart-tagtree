/**
 * Renders tag trees to HTML.
 * (Most programs shouldn't need to use this library directly.)
 *
 * This library implements an algorithm for efficiently updating the DOM
 * whenever a new tag tree is rendered.
 *
 * To use it, you must subclass [RenderRoot] and provide an implementation of
 * [DomUpdater]. A standard implementation built on dart:html is in the
 * tagtree/browser library.
 *
 * Since this library doesn't have a direct dependency on dart:html, it can
 * be tested without a browser.
 */
library render;

import 'package:tagtree/core.dart';
import 'package:tagtree/theme.dart';

import 'dart:async' show EventSink;
import 'dart:convert';

part 'src/render/debug.dart';
part 'src/render/dom.dart';
part 'src/render/event.dart';
part 'src/render/root.dart';
part 'src/render/tree.dart';
part 'src/render/tx/mount.dart';
part 'src/render/tx/transaction.dart';
part 'src/render/tx/unmount.dart';
part 'src/render/tx/update.dart';
