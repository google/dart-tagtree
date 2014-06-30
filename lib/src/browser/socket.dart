part of browser;

/// The Slot tag sends a TagNode to a server over a websocket.
/// The server responds with a stream of tag trees that will be displayed in the slot.
/// [src] is the URL of the websocket to open and [export] contains the tags that
/// may sent over the network.
class Slot extends AnimatedView<View> {
  final String src;
  final HtmlTagSet export;
  const Slot({this.src, this.export});

  @override
  bool checked() {
    assert(src != null);
    assert(export != null);
    return true;
  }

  @override
  Place makePlace() => new SlotPlace(this, firstState);

  @override
  View get firstState => export.Div(inner: "Loading...");

  @override
  View renderFrame(SlotPlace p) {
    p.configure(this);
    return p.state;
  }
}

class SlotPlace extends Place {
  HtmlTagSet $;
  String src;
  _Connection conn;

  SlotPlace(Slot slot, View firstState) : super(firstState) {
    configure(slot);
  }

  void configure(Slot newSlot) {
    if ($ != newSlot.export) {
      $ = newSlot.export;
      if (conn != null) {
        conn.onTagSetChange($);
      }
    }

    if (src != newSlot.src) {
      src = newSlot.src;
      if (conn != null) {
        conn.close();
        conn = null;
      }
      conn = new _Connection(src, this, $);
    }
  }

  void showServerAnimationFrame(View tagTree) {
    nextState = tagTree;
  }

  void showStatus(String message) {
    print(message);
    nextState = $.Div(inner: message);
  }
}

class _Connection {
  final String url;
  final WebSocket ws;
  final SlotPlace slot;

  bool opened = false;
  TaggedJsonCodec codec;

  _Connection(String url, this.slot, TagSet tagSet) :
    this.url = url,
    this.ws = new WebSocket(url)
  {
    ws.onError.listen((_) {
      if (!opened) {
        slot.showStatus("Can't connect to ${url}");
      } else {
        slot.showStatus("Websocket error");
      }
    });

    ws.onMessage.listen((MessageEvent e) {
      if (!opened) {
        print("websocket opened");
      }
      opened = true;
      slot.showServerAnimationFrame(codec.decode(e.data));
    });

    ws.onClose.listen((CloseEvent e) {
      if (!opened) {
        slot.showStatus("Can't connect to ${url} (closed)");
      } else {
        slot.showStatus("Disconnected from ${url}");
      }
    });

    onTagSetChange(tagSet);
  }

  void onTagSetChange(TagSet tags) {
    codec = tags.makeCodec(onEvent: sendEventToServer);
  }

  void sendEventToServer(HandlerCall call) {
    String msg = codec.encode(call);
    ws.sendString(msg);
  }

  void close() {
    ws.close();
  }
}
