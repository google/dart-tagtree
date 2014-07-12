part of core;

/// A function to be called whenever a decoded [RemoteHandler] receives an event.
typedef void OnRemoteHandlerEvent(HandlerEvent event, RemoteHandler handler);

TaggedJsonCodec _makeCodec(TagSet tags, {OnRemoteHandlerEvent onEvent}) {
  if (onEvent == null) {
    onEvent = (e, _) {
      print("ignored event to remote handler: ${e}");
    };
  }

  var types = <JsonType>[];

  for (JsonType type in tags.types) {
    types.add(type);
  }
  for (var type in tags.handlerTypes) {
    types.add(type.eventType);
  }

  types.add(RemoteHandler.$jsonType);
  types.add(RemoteCallback.$jsonType);
  types.add(RawHtml.$jsonType);

  return new TaggedJsonCodec(types, onEvent);
}

