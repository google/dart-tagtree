part of browser;

/// The Slot tag sends a TagNode to a server over a websocket.
/// The server responds with a stream of tag trees that will be displayed in the slot.
/// [src] is the URL of the websocket to open and [tagSet] contains the tags that
/// may sent over the network.
TagNode Slot({String src, HtmlTagSet tagSet}) {
  if (tagSet == null) {
    tagSet = new HtmlTagSet();
  }
  return new TagNode(slotTag, {#src: src, #tagSet: tagSet});
}

final slotTag = new WidgetTag(make: () => new _Slot());

class _Slot extends Widget<TagNode> {
  String src;
  HtmlTagSet $;
  _Connection conn;

  @override
  void setProps(TagNode node) {
    if ($ != node.props.tagSet) {
      $ = node.props.tagSet;
      if (conn != null) {
        conn.onTagSetChange($);
      }
    }

    if (src != node.props.src) {
      src = node.props.src;
      if (conn != null) {
        conn.close();
        conn = null;
      }
      conn = new _Connection(src, this, $);
    }
  }

  @override
  TagNode createFirstState() => $.Div(inner: "Loading...");

  @override
  TagNode render() => state;

  void showServerAnimationFrame(TagNode tagTree) {
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
  final _Slot slot;

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

  void onTagSetChange(TagSet tagSet) {
    codec = makeCodec(tagSet, onEvent: sendEventToServer);
  }

  void sendEventToServer(HandlerCall call) {
    String msg = codec.encode(call);
    ws.sendString(msg);
  }

  void close() {
    ws.close();
  }
}
