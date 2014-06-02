part of core;

typedef TaggedNode NodeMaker(Map<String, dynamic> propsMap);

/// A TagSet defines a set of tags that may be sent over the network.
class TagSet {
  final _nodeMakers = <String, NodeMaker>{};

  final _methodToTag = <Symbol, String>{};
  final _paramToPropKey = <Symbol, Map<Symbol, String>>{};

  final _elementTypes = <String, ElementType>{};
  final _handlerTypes = <String, HandlerType>{};

  void addElement(ElementType type) {
    _elementTypes[type.tag] = type;
    addTag(type.tag, type.makeNode, handlerTypes: type.handlerTypes);
    addMethod(type.method, type.tag, type.namedParams);
  }

  /// Makes a tag available for serialization and deserialization.
  /// If any handlers
  void addTag(String tag, NodeMaker maker, {Iterable<HandlerType> handlerTypes: const []}) {
    _nodeMakers[tag] = maker;
    for (HandlerType t in handlerTypes) {
      _handlerTypes[t.name] = t;
    }
  }

  void addMethod(Symbol method, String tag, Map<Symbol, String> namedParams) {
   assert(method != null);
   assert(tag != null);
   assert(namedParams != null);
   assert(_nodeMakers[tag] != null);
    _methodToTag[method] = tag;
    _paramToPropKey[method] = namedParams;
  }

  Iterable<String> get tags => _nodeMakers.keys;

  /// Returns the types of all the element tags included in this set.
  Iterable<ElementType> get elementTypes => _elementTypes.values;

  /// Returns the types of all the handlers used by tags in this set.
  Iterable<HandlerType> get handlerTypes => _handlerTypes.values;

  NodeMaker getMaker(String tag) => _nodeMakers[tag];

  TaggedNode makeNode(String tag, Map<String, dynamic> propsMap) =>
      _nodeMakers[tag](propsMap);

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
        return makeNode(tag, propsMap);
      }
    }
    return super.noSuchMethod(inv);
  }
}
