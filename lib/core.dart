/**
 * This library includes the core data structures shared between client and server.
 *
 * To render a tag tree in a browser, you also need package:tagtree/browser.dart.
 * To handle sessions on the server, you also need package:tagtree/server.dart.
 */
library core;

import 'package:tagtree/json.dart';

part 'src/core/handler.dart';
part 'src/core/json.dart';
part 'src/core/tag.dart';
part 'src/core/tagtype.dart';
part 'src/core/tagset.dart';
part 'src/core/tagnode.dart';
