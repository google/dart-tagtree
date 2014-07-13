part of core;

/// A TagSet acts as a factory for a set of tags.
///
/// Tags can be created in two ways: using a method call (handled by
/// noSuchMethod), or from JSON, using the codec returned by [makeCodec]).
class TagSet {
  final Iterable<JsonType> types;

  const TagSet(this.types);

  TagSet.concat(Iterable<JsonType> types1, Iterable<JsonType> types2) :
    this.types = new List<JsonType>.from(types1)..addAll(types2);

  bool checked() => _init();

  bool _init() {
    if (_byJson[this] != null) {
      return true;
    }

    var byJson = <String, JsonType>{};
    var byMethod = <Symbol, TagType>{};

    addType(JsonType newType) {
      var prev = byJson[newType.tagName];
      if (prev == newType) {
        return;
      } else if (prev == null) {
        byJson[newType.tagName] = newType;
        for (var dep in newType.deps) {
          addType(dep);
        }
        return;
      } else {
        throw "already added: ${prev.tagName}";
      }
    }

    for (JsonType type in types) {
      if (type is TagType) {
        assert(type.checked());
      }

      addType(type);

      if (type is TagType) {
        if (type.canDecodeInvocation) {
          assert(byMethod[type.method] == null);
          byMethod[type.method] = type;
        }
      }
    }

    _byJson[this] = byJson;
    _byMethod[this] = byMethod;
    return true;
  }

  Map<String, JsonType> get byJson {
    _init();
    return _byJson[this];
  }

  Map<Symbol, TagType> get byMethod {
    _init();
    return _byMethod[this];
  }

  Iterable<String> get jsonTags => byJson.keys;

  /// Creates a codec for sending and receiving tags and events.
  TaggedJsonCodec makeCodec({RegisterFunction register, OnRemoteCall onCall}) {

    var types = <JsonType>[
        HandlerEvent.$jsonType,
        FunctionKey.$jsonType,
        FunctionCall.$jsonType,
        RawHtml.$jsonType
    ]..addAll(this.types);

    return new TaggedJsonCodec(types, register: register, onCall: onCall);
  }

  /// Creates Tags from method calls using the tag's method name.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      TagType meta = byMethod[inv.memberName];
      if (meta != null) {
        return meta.fromInvocation(inv);
      }
    }
    return super.noSuchMethod(inv);
  }

  static final _byJson = new Expando<Map<String, JsonType>>();
  static final _byMethod = new Expando<Map<Symbol, TagType>>();
}
