/// Tail a file and show it in the browser.
/// When the file changes, the browser view will automatically update.

import "dart:async" show Completer, Future, StreamController;
import "dart:convert" show UTF8;
import "dart:io";

import "package:viewtree/core.dart";

final SAFE_FILE_PATH = new RegExp(r"^/(\w+/)*\w+(\.\w+)*$");
final FILE_EXTENSION = new RegExp(r"\.(\w+)$");

main(List<String> args) {
  if (args.length == 0) {
    start(new File(Platform.script.toFilePath()));
  } else if (args.length == 1) {
    start(new File(args[0]));
  } else {
    exitUsage();
  }
}

start(File tailFile) {
  if (!FileSystemEntity.isWatchSupported) {
    print("Sorry, file watching isn't supported on this OS.");
    exit(1);
  }
  if (!tailFile.existsSync()) {
    print("file doesn't exist: ${tailFile}");
    exitUsage();
  }

  String webDir = Platform.script.resolve("web").toFilePath();
  String packagesDir = Platform.script.resolve('packages').toFilePath();

  HttpServer.bind("localhost", 8080).then((server) {
    print("\nThe server is ready. Please connect to http://localhost:8080 using Dartium\n");
    server.listen((request) {
      String path = request.uri.path;
      if (path == "/") {
        sendFile(request, "${webDir}/client.html");
      } else if (SAFE_FILE_PATH.matchAsPrefix(path) == null) {
        sendNotFound(request);
      } else if (path == "/client.html" || path == "/client.dart") {
        sendFile(request, "${webDir}${path}");
      } else if (path == "/ws") {
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          print("websocket connected");
          sendTailFrames(socket, tailFile);
        });
      } else if (path.startsWith("/packages/")) {
        var filePath = "${packagesDir}${path.replaceFirst("/packages/", "/")}";
        sendFile(request, filePath);
      } else if (path == "/tail") {
        sendTail(request, tailFile);
      } else {
        sendNotFound(request);
      }
    });
  });
}

exitUsage() {
  print("Usage: dart tail.dart <filename>");
  exit(1);
}

/// Sends a snapshot of the file's tail every time it changes.
sendTailFrames(WebSocket socket, File f) {
  sendFrame(socket, f);
  f.watch().listen((_) {
    sendFrame(socket, f);
  });
}

sendFrame(WebSocket socket, File f) {
  lastLines(f, 50).then((List<String> lines) {
    print("sending tail view");
    TailView view = new TailView(f.path, lines);
    View tree = view.render();
    String encoded = Elt.rules.encodeTree(tree);
    socket.add(encoded);
  });
}

final $ = new Tags();

/// TailView renders the tail of a file as a ViewTree.
/// (This is an example of a server-side View.)
class TailView extends Widget {
  TailView(String title, List<String> lines) : super({#title: title, #lines: lines});

  @override
  View render() {
    List<String> lines = props.lines;
    return $.Div(inner: [
        $.H1(inner: "The last ${lines.length} lines of  ${props.title}"),
        $.Pre(inner: lines.join("\n"))
        ]);
  }
}

sendFile(HttpRequest request, String filePath) {
  var f = new File(filePath);
  f.exists().then((exists) {
    if (!exists) {
      sendNotFound(request);
      return;
    }
    Match m = FILE_EXTENSION.firstMatch(f.path);
    String extension = (m == null) ? null : m.group(1);
    var type = chooseContentType(extension);

    request.response.headers.contentType = type;
    f.openRead().pipe(request.response).then((_) {
      request.response.close();
    });
  });
}

ContentType chooseContentType(String extension) {
  if (extension == "html") {
    return new ContentType("text", "html", charset: "UTF8");
  } else if (extension == "js" || extension == "dart") {
    return new ContentType("text", "plain", charset: "UTF8");
  } else {
    return new ContentType("application", "binary");
  }
}

sendTail(HttpRequest request, File f) {
  print("sending tail file for ${request.uri.path}");
  lastLines(f, 10).then((List<String> lines) {
    request.response
        ..write(lines.join("\n"))
        ..close();
  });
}

sendNotFound(HttpRequest request) {
  print("sending not found for ${request.uri.path}");
  request.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..write('Not found')
      ..close();
}

/// Returns the last lines of the given file.
Future<List<String>> lastLines(File f, int linesWanted, {int sizeGuess}) {
  if (sizeGuess == null) {
    sizeGuess = linesWanted * 100;
  }
  return f.length().then((len) {
    int start = len > sizeGuess ? (len - sizeGuess) : 0;
    if (start == 0) {
      return f.readAsLines().then((lines) {
        if (lines.length > linesWanted) {
          return lines.sublist(lines.length - linesWanted);
        } else {
          return lines;
        }
      });
    }

    return UTF8.decodeStream(f.openRead(start)).then((String contents) {
      var lines = contents.split("\n");
      if (lines.isEmpty) {
        return lines;
      }
      lines = lines.sublist(1); // discard partial line
      if (lines.length >= linesWanted) {
        return lines.sublist(lines.length - linesWanted);
      }
      // not enough lines; try a larger guess
      return lastLines(f, linesWanted, sizeGuess: sizeGuess * 2);
    });
  });
}
