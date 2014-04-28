part of json;

/// Creates a codec that can encode any HTML tags or events supported by a TagMaker.
TaggedJsonCodec makeCodec(TagMaker tags) {
  var rs = [];
  for (TagDef def in tags.defs) {
    if (def is EltDef) {
      rs.add(new EltRule(tags, def));
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
class EltRule extends JsonRule<Tag> {
  TagMaker _maker;
  EltDef _def;

  EltRule(this._maker, EltDef def) :
    _def = def,
    super(def.tagName);

  @override
  bool appliesTo(Jsonable instance) => instance is Tag && instance.def == _def;

  @override
  encode(Tag instance) {
    Map<Symbol, dynamic> props = instance.propMap;
    var state = {};
    for (Symbol sym in props.keys) {
      var field = _def.getJsonPropName(sym);
      assert(field != null);
      state[field] = props[sym];
    }
    return state;
  }

  @override
  Tag decode(Map<String, dynamic> state) {
    var props = <Symbol, dynamic>{};
    for (String field in state.keys) {
      var sym = _def.getJsonPropKey(field);
      assert(sym != null);
      props[sym] = state[field];
    }
    return _maker.makeTag(_def.methodName, props);
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

