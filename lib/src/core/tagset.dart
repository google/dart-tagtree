part of core;

typedef View ViewMakerFunc(Map<String, dynamic> propsMap);

/// A TagSet creates views from tags and properties.
/// It defines a set of View classes and HandlerTypes that may be sent
/// over the network.
class TagSet {
  final _viewMaker = <String, ViewMakerFunc>{};

  final _methodToTag = <Symbol, String>{};
  final _paramToPropKey = <Symbol, Map<Symbol, String>>{};

  final _elementTypes = <String, ElementType>{};
  final _handlerTypes = <String, HandlerType>{};

  /// Defines the tag and method for creating an HTML element.
  void defineElement(ElementType type) {
    _elementTypes[type.tag] = type;
    defineTag(type.tag, type.makeView, handlerTypes: type.handlerTypes);
    defineMethod(type.method, type.namedParams, type.tag);
  }

  /// Defines a tag so that its corresponding View can be created using [makeView].
  void defineTag(String tag, ViewMakerFunc maker, {Iterable<HandlerType> handlerTypes: const []}) {
    _viewMaker[tag] = maker;
    for (HandlerType t in handlerTypes) {
      _handlerTypes[t.name] = t;
    }
  }

  /// Defines a method so that it will create the View with the given tag.
  /// (The tag must already be defined.)
  void defineMethod(Symbol method, Map<Symbol, String> namedParams, String tagToCreate) {
   assert(method != null);
   assert(namedParams != null);
   assert(tagToCreate != null);
   assert(_viewMaker[tagToCreate] != null);
    _methodToTag[method] = tagToCreate;
    _paramToPropKey[method] = namedParams;
  }

  Iterable<String> get tags => _viewMaker.keys;

  /// Returns the types of all the element tags included in this set.
  Iterable<ElementType> get elementTypes => _elementTypes.values;

  /// Returns the types of all the handlers used by tags in this set.
  Iterable<HandlerType> get handlerTypes => _handlerTypes.values;

  ViewMakerFunc getMaker(String tag) => _viewMaker[tag];

  View makeView(String tag, Map<String, dynamic> propsMap) =>
      _viewMaker[tag](propsMap);

  /// Tags may also be created by calling a method with the same name.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      String tag = _methodToTag[inv.memberName];
      if (tag != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "positional arguments not supported when creating tags";
        }
        var toKey = _paramToPropKey[inv.memberName];
        var propsMap = <String, dynamic>{};
        for (Symbol name in inv.namedArguments.keys) {
          propsMap[toKey[name]] = inv.namedArguments[name];
        }
        return makeView(tag, propsMap);
      }
    }
    return super.noSuchMethod(inv);
  }
}
