/**
 * Allows a server written in Dart to render a stream of tag trees over a web socket
 * and receive events.
 */
library server;

import 'package:tagtree/core.dart' as core;
import 'package:tagtree/widget.dart' show StateMixin;

import 'dart:async' show scheduleMicrotask;
import 'dart:convert' show Codec;
import 'dart:io';

export 'package:tagtree/html.dart';

part 'src/server/session.dart';
part 'src/server/tag.dart';
part 'src/server/socket.dart';
