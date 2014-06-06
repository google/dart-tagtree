/**
 * A library that allows a server-side object to display its user interface in a web page.
 * (This is the only TagTree library that can't run in a browser.)
 *
 * A [Session] is a server-side object that has a TagTree-based user interface.
 * A [WebSocketRoot] runs a Session with its input and output connected to a WebSocket.
 * It can then send tag trees over the socket and recieve events in response.
 * (The web page should use a Slot and SlotWidget for its end of the connection.)
 */
library server;

import 'package:tagtree/core.dart' as core;
import 'package:tagtree/widget.dart' show StateMixin;

import 'dart:async' show scheduleMicrotask;
import 'dart:convert' show Codec;
import 'dart:io';

export 'package:tagtree/html.dart';

part 'src/server/session.dart';
part 'src/server/socket.dart';
