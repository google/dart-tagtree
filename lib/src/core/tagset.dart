part of core;

/// A TagSet acts as a factory for a set of [JsonTag]s.
///
/// Tags can be created in two ways: using a method call (handled by
/// noSuchMethod), or from JSON, using the codec returned by
/// [makeCodec]).
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
    var byMethod = <Symbol, TagMaker>{};
    var handlerTypes = <String, HandlerType>{};

    for (JsonType type in types) {
      if (type is TagMaker) {
        assert(type.checked());
      }
      assert(byJson[type.tagName] == null);

      byJson[type.tagName] = type;
      if (type is TagMaker) {
        for (var handler in type.handlers) {
          var prev = handlerTypes[handler.propKey];
          assert(prev == null || prev == handler);
          handlerTypes[handler.propKey] = handler;
        }
        if (type.canDecodeInvocation) {
          assert(byMethod[type.method] == null);
          byMethod[type.method] = type;
        }
      }
    }

    _byJson[this] = byJson;
    _byMethod[this] = byMethod;
    _handlerTypes[this] = handlerTypes.values;
    return true;
  }

  Map<String, JsonType> get byJson {
    _init();
    return _byJson[this];
  }

  Map<Symbol, TagMaker> get byMethod {
    _init();
    return _byMethod[this];
  }

  Iterable<String> get jsonTags => byJson.keys;

  /// Returns the types of all the handlers used by tags in this set.
  Iterable<HandlerType> get handlerTypes {
    _init();
    return _handlerTypes[this];
  }

  /// Creates a codec for sending and receiving [Tag]s and
  /// [RemoteCallback]s. Whenever a Handler is received,
  /// it will be replaced with a [HandlerFunc] that calls
  /// the given onEvent function.
  TaggedJsonCodec makeCodec({OnRemoteHandlerEvent onEvent}) =>
      _makeCodec(this, onEvent: onEvent);

  /// Creates Tags from method calls using the tag's method name.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      TagMaker meta = byMethod[inv.memberName];
      if (meta != null) {
        return meta.fromInvocation(inv);
      }
    }
    return super.noSuchMethod(inv);
  }

  static final _byJson = new Expando<Map<String, JsonType>>();
  static final _byMethod = new Expando<Map<Symbol, TagMaker>>();
  static final _handlerTypes = new Expando<Iterable<HandlerType>>();
}
