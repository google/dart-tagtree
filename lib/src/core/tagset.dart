part of core;

/// A TagSet acts as a factory for a set of [JsonTag]s.
///
/// Tags can be created in two ways: using a method call (handled by
/// noSuchMethod), or from JSON, using the codec returned by
/// [makeCodec]).
class TagSet {
  final Iterable<TagMaker> makers;

  const TagSet(this.makers);

  TagSet.concat(Iterable<TagMaker> makers1, Iterable<TagMaker> makers2) :
    this.makers = new List<TagMaker>.from(makers1)..addAll(makers2);

  bool checked() => _init();

  bool _init() {
    if (_byJson[this] != null) {
      return true;
    }

    var byJson = <String, TagMaker>{};
    var byMethod = <Symbol, TagMaker>{};
    var handlerTypes = <String, HandlerType>{};

    for (var meta in makers) {
      assert(meta.checked());
      if (meta.canDecodeJson) {
        assert(byJson[meta.tagName] == null);
        byJson[meta.tagName] = meta;
        for (var handler in meta.handlers) {
          var prev = handlerTypes[handler.propKey];
          assert(prev == null || prev == handler);
          handlerTypes[handler.propKey] = handler;
        }
      }
      if (meta.canDecodeInvocation) {
        assert(byMethod[meta.method] == null);
        byMethod[meta.method] = meta;
      }
    }

    _byJson[this] = byJson;
    _byMethod[this] = byMethod;
    _handlerTypes[this] = handlerTypes.values;
    return true;
  }

  Map<String, TagMaker> get byJson {
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

  static final _byJson = new Expando<Map<String, TagMaker>>();
  static final _byMethod = new Expando<Map<Symbol, TagMaker>>();
  static final _handlerTypes = new Expando<Iterable<HandlerType>>();
}
