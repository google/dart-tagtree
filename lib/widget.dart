/**
 * A [Widget] runs within the rendered tag tree until the tree is re-rendered without the
 * corresponding view. The [StateMixin] implements automatic dirty-tracking for Widgets.
 */
library widget;

import 'dart:async' show Stream, StreamController, StreamSink, EventSink;

import 'package:tagtree/core.dart';

part 'src/widget/state.dart';
part 'src/widget/widget.dart';