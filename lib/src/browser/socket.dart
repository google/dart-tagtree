part of browser;

/// Mounts a stream of views deserialized from a websocket.
///
/// The CSS selectors point to the container element where the views will be displayed.
/// The ruleSet will be used to deserialize the stream. (Only tags defined in the ruleset
/// can be deserialized.)
mountWebSocket(String webSocketUrl, String selectors, core.HtmlTagSet maker) {
  final $ = maker;
  final codec = core.makeCodec($);

  showStatus(String message) {
    print(message);
    root(selectors).mount($.Div(inner: message));
  }

  bool opened = false;
  var ws = new WebSocket(webSocketUrl);

  void onEvent(core.HandlerCall call) {
    String json = codec.encode(call);
    ws.sendString(json);
  }

  ws.onError.listen((_) {
    if (!opened) {
      showStatus("Can't connect to ${webSocketUrl}");
    } else {
      showStatus("Websocket error");
    }
  });

  ws.onMessage.listen((MessageEvent e) {
    if (!opened) {
      print("websocked opened");
    }
    opened = true;
    core.TagNode tag = codec.decode(e.data);
    render.HandleFunc func = onEvent;
    root(selectors).mount(tag, handler: func);
  });

  ws.onClose.listen((CloseEvent e) {
    if (!opened) {
      showStatus("Can't connect to ${webSocketUrl} (closed)");
    } else {
      showStatus("Disconnected from ${webSocketUrl}");
    }
  });
}