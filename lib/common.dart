/**
 * Commonly-used classes that don't need to be in core.
 *
 * [AnimatedTag] and [TemplateTag] are shortcuts for implementing a [Tag]'s
 * default [Animator] in the same class.
 *
 * [Template] is a simplification of [Animator] for stateless animations.
 */
library common;

import 'package:tagtree/core.dart';

part "src/common/animatedtag.dart";
part "src/common/template.dart";
