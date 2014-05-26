part of core;

/// A set of tags that starts out empty.
class TagSet {
  final _methodToTag = <Symbol, Tag>{};
  final _handlerTypes = <Symbol, HandlerType>{};

  /// Adds a tag to the set. Automatically exports a method for constructing new tag nodes.
  /// If the method is null, the TagType's symbol will be used as the method name.
  void addTag(Symbol method, Tag tag) {
    assert(tag.checked());
    if (method == null) {
      assert(tag.type != null);
      method = tag.type.symbol;
    }
    assert(!(_methodToTag.containsKey(method)));
    _methodToTag[method] = tag;
    if (tag.type != null) {
      for (PropType p in tag.type.props) {
        if (p is HandlerType) {
          _handlerTypes[p.sym] = p;
        }
      }
    }
  }

  /// Creates a new tag for any of the TagDefs in this set.
  TagNode makeNode(Symbol method, Map<Symbol, dynamic> props) {
    Tag tag = _methodToTag[method];
    if (tag == null) {
      throw "can't find method for constructing a tag node: ${method}";
    }
    return new TagNode(tag, props);
  }

  /// Returns each tag in this TagSet.
  Iterable<Tag> get values => _methodToTag.values;

  /// Returns the handler types supported by tags in this set.
  Iterable<HandlerType> get handlerTypes => _handlerTypes.values;

  /// Tags may also be created by calling a method with the same name.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      Tag tag = _methodToTag[inv.memberName];
      if (tag != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "positional arguments not supported when creating tags";
        }
        return new TagNode(tag, inv.namedArguments);
      }
    }
    return super.noSuchMethod(inv);
  }
}
