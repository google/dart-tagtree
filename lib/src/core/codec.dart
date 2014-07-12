part of core;

/// A function to be called whenever a decoded [RemoteHandler] receives an event.
typedef void OnRemoteHandlerEvent(HandlerEvent event, RemoteHandler handler);

TaggedJsonCodec _makeCodec(TagSet tags, {OnRemoteHandlerEvent onEvent}) {
  if (onEvent == null) {
    onEvent = (e, _) {
      print("ignored event to remote handler: ${e}");
    };
  }

  var rules = <JsonRule>[];

  for (TagMaker meta in tags.makers) {
    rules.add(meta);
  }

  rules.add(RemoteHandler.$jsonType);
  rules.add(RemoteCallback.$jsonType);
  for (var type in tags.handlerTypes) {
    rules.add(type.eventType);
  }
  rules.add(RawHtml.$jsonType);

  return new TaggedJsonCodec(rules, [const JsonableFinder()], onEvent);
}

