/**
 * The core data structures used in TagTree.
 * (This library should work anywhere Dart will run, both in browsers and on servers.)
 *
 * Tag trees are built out of [Tag] nodes. A Tag's fields can often be
 * inspected by converting it to a [PropsMap]. Some fields may hold
 * a [HandlerFunc], which which will be called when a rendered View fires
 * a [HandlerEvent].
 *
 * An [ElementTag] is a View that renders to an HTML element. Its structure is
 * defined by an [ElementType].
 *
 * A [Animator] implements a [Tag]. The [ElementType] and [Template] viewers are
 * included in core. Viewers for multiple kinds of views are collected into a [Theme].
 *
 * A [TagSet] can create the corresponding View for each of a set of tags.
 * The [TagSet.makeCodec] function returns a codec that can convert trees
 * to and from JSON strings.
 */
library core;

import 'dart:collection';
import 'package:tagtree/json.dart';

part 'src/core/animator.dart';
part 'src/core/element.dart';
part 'src/core/handler.dart';
part 'src/core/json.dart';
part 'src/core/place.dart';
part 'src/core/state.dart';
part 'src/core/tagset.dart';
part 'src/core/template.dart';
part 'src/core/theme.dart';
part 'src/core/tag.dart';
