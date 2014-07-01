part of core;

/// A function for creating a View from its JSON properties.
typedef Tag ViewDecodeFunc(Map<String, dynamic> propsMap);

/// A TagSet creates views from tags and properties.
/// It defines a set of View classes and HandlerTypes that may be sent
/// over the network.
class TagSet {
  final _decoders = <String, ViewDecodeFunc>{};

  final _methodToJsonTag = <Symbol, String>{};
  final _paramToPropKey = <Symbol, Map<Symbol, String>>{};

  final _elementTypes = <String, ElementType>{};
  final _handlerTypes = <String, HandlerType>{};

  /// Defines the tag and method for creating an HTML element.
  void defineElement(ElementType type) {
    _elementTypes[type.htmlTag] = type;
    export(type.htmlTag, type.makeTag, handlerTypes: type.handlerTypes);
    defineMethod(type.method, type.namedParamToKey, type.htmlTag);
  }

  /// Exports a tag so that it can be transmitted as JSON.
  void export(String jsonTag, ViewDecodeFunc decode, {Iterable<HandlerType> handlerTypes: const []}) {
    _decoders[jsonTag] = decode;
    for (HandlerType t in handlerTypes) {
      _handlerTypes[t.propKey] = t;
    }
  }

  /// Defines a method so that it will create the View with the given tag.
  /// (The tag must already be defined.)
  void defineMethod(Symbol method, Map<Symbol, String> namedParams, String tagToCreate) {
   assert(method != null);
   assert(namedParams != null);
   assert(tagToCreate != null);
   assert(_decoders[tagToCreate] != null);
    _methodToJsonTag[method] = tagToCreate;
    _paramToPropKey[method] = namedParams;
  }

  Iterable<String> get jsonTags => _decoders.keys;

  /// Returns the types of all the handlers used by tags in this set.
  Iterable<HandlerType> get handlerTypes => _handlerTypes.values;

  /// Returns the JSON decoder for a tag.
  ViewDecodeFunc getDecoder(String jsonTag) => _decoders[jsonTag];

  /// Creates a codec for sending and receiving [Tag]s and
  /// [HandlerCall]s. Whenever a Handler is received,
  /// it will be replaced with a [HandlerFunc] that calls
  /// the given onEvent function.
  TaggedJsonCodec makeCodec({OnEventFunc onEvent}) =>
      _makeCodec(this, onEvent: onEvent);

  /// Tags may also be created by calling a method with the same name.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      String tag = _methodToJsonTag[inv.memberName];
      if (tag != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "positional arguments not supported when creating tags";
        }
        var toKey = _paramToPropKey[inv.memberName];
        var propsMap = <String, dynamic>{};
        for (Symbol name in inv.namedArguments.keys) {
          var propKey = toKey[name];
          if (propKey == null) {
            throw "no property found for ${name} in ${tag}";
          }
          propsMap[toKey[name]] = inv.namedArguments[name];
        }
        return getDecoder(tag)(propsMap);
      }
    }
    return super.noSuchMethod(inv);
  }
}
