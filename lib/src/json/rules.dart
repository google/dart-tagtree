part of json;

/// Creates a codec that can encode any HTML tags or events supported by a TagMaker.
TaggedJsonCodec makeCodec(TagSet tags) {
  var rs = [];
  for (TagDef def in tags.defs) {
    if (def.type != null) {
      rs.add(new JsonableTagRule(def));
    }
  }
  rs.add(new _HandleRule());
  for (Symbol key in tags.handlerNames.keys) {
    if (key == #onChange) {
      rs.add(new _ChangeEventRule());
    } else {
      rs.add(new _EventRule(key, tags.handlerNames[key]));
    }
  }
  rs.add(new _HandleCallRule());
  return new TaggedJsonCodec(rs);
}

/// Encodes an Elt as tagged JSON.
class JsonableTagRule extends JsonRule<JsonableTag> {
  final TagDef _def;

  JsonableTagRule(TagDef def) :
    _def = def,
    super(def.jsonMapper.tagName);

  @override
  bool appliesTo(Jsonable instance) => instance is JsonableTag && instance.def == _def;

  @override
  encode(JsonableTag instance) => instance.propsToJson();

  @override
  TagNode decode(Map<String, dynamic> state) {
    var props = _def.jsonMapper.propsFromJson(state);
    return _def.makeTag(props);
  }
}

class _HandleRule extends JsonRule<Handle> {
  _HandleRule(): super("handle");

  @override
  bool appliesTo(Jsonable instance) => (instance is Handle);

  @override
  encode(Handle h) => [h.frameId, h.id];

  @override
  Jsonable decode(array) {
    if (array is List && array.length >= 2) {
      return new Handle(array[0], array[1]);
    } else {
      throw "can't decode Handle: ${array.runtimeType}";
    }
  }
}

class _EventRule extends JsonRule<HtmlEvent> {
  final Symbol _type;

  _EventRule(Symbol type, String tagName) : super(tagName), _type = type;

  @override
  bool appliesTo(Jsonable instance) => (instance is HtmlEvent);

  @override
  encode(HtmlEvent e) => e.targetPath;

  @override
  HtmlEvent decode(s) {
    if (s is String) {
      return new HtmlEvent(_type, s);
    } else {
      throw "can't decode ViewEvent: ${s.runtimeType}";
    }
  }
}

class _ChangeEventRule extends JsonRule<ChangeEvent> {
  _ChangeEventRule() : super("onChange");

  @override
  bool appliesTo(Jsonable instance) => (instance is ChangeEvent);

  @override
  encode(ChangeEvent e) => {
    "target": e.targetPath,
    "value": e.value,
  };

  @override
  HtmlEvent decode(map) => new ChangeEvent(map["target"], map["value"]);
}

class _HandleCallRule extends JsonRule<HandleCall> {
  _HandleCallRule() : super("call");

  @override
  bool appliesTo(Jsonable instance) => (instance is HandleCall);

  @override
  encode(HandleCall call) => [call.handle.frameId, call.handle.id, call.event];

  @override
  HandleCall decode(array) {
    if (array is List && array.length >= 3) {
      return new HandleCall(new Handle(array[0], array[1]), array[2]);
    } else {
      throw "can't decode HandleCall: ${array.runtimeType}";
    }
  }
}

