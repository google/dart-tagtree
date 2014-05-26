part of core;

/// A set of tags that may be used to construct a tag tree.
/// Automatically includes HTML tags.
class HtmlTagSet extends TagSet with HtmlTags {
  HtmlTagSet() {
    for (var tag in htmlTags) {
      addTag(tag.type.symbol, tag);
    }
  }

  /// Returns the parameter name and corresponding JSON tag of each HTML handler
  /// supported by this TagSet.
  Map<Symbol, String> get handlerNames => _htmlHandlerNames;

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

/// A set of tags that starts out empty.
class TagSet {
  final Map<Symbol, Tag> _methodToTag = <Symbol, Tag>{};

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
