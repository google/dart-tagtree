library tail;

/// A websocket server that shows the last few lines of a file.
/// Whenever the file changes, the browser view will automatically update.
/// To use: run this command and then run web/client.html in Dartium.

import "dart:async";
import "dart:convert" show UTF8;
import "dart:io";

import "package:tagtree/core.dart";
import "package:tagtree/server.dart";

import '../web/shared.dart';

final $ = new HtmlTagSet();

class TailAnimator extends Animator<TailDemoRequest, Tail> {
  final TailWatcher watcher;

  TailAnimator(this.watcher);

  @override
  Place start(_) {
    var p = new Place(watcher.currentValue);

    var sub = watcher.onChange.listen((Tail t) {
      p.nextState = t;
    });

    p.onCut = (_) {
      sub.cancel();
    };

    return p;
  }

  @override
  Tag renderAt(Place<Tail> p, TailDemoRequest tag) {
    Tail t = p.state.suffix(tag.lineCount);
    return $.Div(inner: [
        $.H1(inner: "Tail Demo"),
        $.H2(inner: "The last ${t.lines.length} lines of ${t.file.path}"),
        new TailSnapshot(lines: t.lines)
    ]);
  }
}

// Model

class Tail {
  final File file;
  final List<String> lines;
  Tail(this.file, this.lines);

  Tail suffix(int lineCount) {
    int skip = lines.length - lineCount;
    if (skip < 0) {
      skip = 0;
    }
    return new Tail(file, lines.sublist(skip));
  }
}

/// Watches a file for changes.
///
/// When a change happens, currentValue is updated and a Tail is sent to the onChange stream.
class TailWatcher {
  final File file;
  final int lineCount;
  Tail currentValue;
  final _onChange = new StreamController<Tail>.broadcast();

  bool loadRequested = false;
  bool loading = false;

  TailWatcher(this.file, this.lineCount) {
    _requestLoad();
    file.watch().listen((_) => _requestLoad());
  }

  Stream<Tail> get onChange => _onChange.stream;

  _requestLoad() {
    // ensure that only one load happens at a time
    if (loading) {
      loadRequested = true;
      return;
    }
    loadRequested = false;
    loadTail(file, lineCount).then(_onLoaded).catchError((e) {
      print("loadTail failed: ${e}");
      loading = false;
    });
    loading = true;
  }

  _onLoaded(Tail tail) {
    currentValue = tail;
    _onChange.add(tail);
    loading = false;
    if (loadRequested) {
      _requestLoad();
    }
  }
}

/// Returns the last lines of the given file.
Future<Tail> loadTail(File f, int linesWanted, {int sizeGuess}) {
  if (sizeGuess == null) {
    sizeGuess = linesWanted * 100;
  }
  return f.length().then((len) {
    int start = len > sizeGuess ? (len - sizeGuess) : 0;
    if (start == 0) {
      return f.readAsLines().then((lines) {
        if (lines.length > linesWanted) {
          return new Tail(f, lines.sublist(lines.length - linesWanted));
        } else {
          return new Tail(f, lines);
        }
      });
    }

    return UTF8.decodeStream(f.openRead(start)).then((String contents) {
      var lines = contents.split("\n");
      if (lines.isEmpty) {
        return new Tail(f, lines);
      }
      lines = lines.sublist(1); // discard partial line
      if (lines.length >= linesWanted) {
        return new Tail(f, lines.sublist(lines.length - linesWanted));
      }
      // not enough lines; try a larger guess
      return loadTail(f, linesWanted, sizeGuess: sizeGuess * 2);
    });
  });
}

