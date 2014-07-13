/**
 * A library that allows a server-side Animator to display its user interface in a web page.
 * (This is the only TagTree library that can't run in a browser.)
 *
 * A [WebSocketRoot] runs an Animator with its input and output connected to a WebSocket.
 * It can then send tag trees over the socket and recieve events in response.
 * (The web page should use a RemoteZone for its end of the connection.)
 */
library server;

import 'package:tagtree/core.dart' as core;
import 'package:tagtree/json.dart' show Jsonable, FunctionKey, FunctionCall, UnknownTagException;

import 'dart:async' show scheduleMicrotask, Stream;
import 'dart:convert' show Codec;
import 'dart:io';

export 'package:tagtree/core.dart';
export 'package:tagtree/common.dart';
export 'package:tagtree/html.dart';
export 'package:tagtree/json.dart' show Jsonable;

part 'src/server/socket.dart';
