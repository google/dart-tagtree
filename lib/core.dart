/**
 * The core data structures used in TagTree.
 * (This library should work anywhere Dart will run, both in browsers and on servers.)
 *
 * Tag trees are built out of [Tag] nodes. A Tag's fields can often be
 * inspected by converting it to a [PropsMap]. Some fields may hold
 * a [HandlerFunc], which which will be called when a rendered Tag fires
 * a [HandlerEvent].
 *
 * An [ElementTag] is a tag that renders to an HTML element. Its structure is
 * defined by an [ElementType].
 *
 * A [Animator] implements a [Tag]. A [Theme] is a mapping from Tags to Animators.
 *
 * A [TagSet] is a factory object for creating Tags.
 * The [TagSet.makeCodec] function returns a codec that can convert trees
 * to and from JSON strings.
 */
library core;

import 'dart:collection';
import 'package:tagtree/json.dart';

export 'package:tagtree/json.dart' show JsonType, Jsonable;

part 'src/core/animator.dart';
part 'src/core/element.dart';
part 'src/core/handler.dart';
part 'src/core/jsontag.dart';
part 'src/core/place.dart';
part 'src/core/state.dart';
part 'src/core/tagtype.dart';
part 'src/core/tagset.dart';
part 'src/core/theme.dart';
part 'src/core/tag.dart';
