/**
 * A [Theme] controls how tag trees are rendered to web pages.
 *
 * A tag can be implemented using [Theme.defineElement], [Theme.defineTemplate], or
 * [Theme.defineWidget]. A [Widget] runs within the _rendered_ tag tree until the
 * tree is re-rendered without the corresponding tag. The [StateMixin] implements
 * automatic dirty-tracking for Widgets.
 */
library theme;

import 'dart:async' show Stream, StreamController, StreamSink;

import 'package:tagtree/core.dart';

part 'src/theme/state.dart';
part 'src/theme/theme.dart';
part 'src/theme/widget.dart';