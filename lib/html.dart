/**
 * The standard HTML tags supported by TagTree.
 * (This library should work anywhere Dart will run, both in browsers and on servers.)
 *
 * The [HtmlTagSet] class has methods for creating each HTML element supported by TagTree.
 *
 * TagSets are extendable, so you can add your own definitions for any tags that are missing.
 * (In principle, this should work with custom HTML tags.)
 */
library html;

import 'package:tagtree/core.dart';

part 'src/html/events.dart';
part 'src/html/tags.dart';
