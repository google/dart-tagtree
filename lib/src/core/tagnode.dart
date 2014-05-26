part of core;

/// TagNodes form a tree data structure similar to a tree of HTML elements.
/// They are more general than HTML elements because they support custom tags without
/// requiring any browser support.
///
/// Each node has a [Tag] that determines its behavior: whether it has state,
/// how it will be rendered to HTML, and whether it can be serialized as JSON.
///
/// A node's props are similar to HTML attributes, but instead of storing a string,
/// they sometimes store arbitrary JSON, child tags, or callback functions.
///
/// The children of a node (if any) are usually stored in its "inner" prop.
class TagNode {
  final Tag tag;
  final Map<Symbol, dynamic> _propsMap;
  Props _props;

  TagNode(this.tag, this._propsMap) {
    assert(tag.checkNode(this));
  }

  /// Returns the key of each prop.
  Iterable<Symbol> get propKeys => _propsMap.keys;

  /// Returns the value of a property.
  operator[](Symbol key) => _propsMap[key];

  /// Provides access to the tag's props as fields.
  Props get props {
    if (_props == null) {
      _props = new Props(_propsMap);
    }
    return _props;
  }

  /// Calls a function with this node's props as named parameters.
  applyProps(Function f) => Function.apply(f, [], _propsMap);

  /// Returns this node's props as a map with string keys instead of symbols.
  /// (The tag must have a type.)
  Map<String, dynamic> get propsWithStringKeys {
    assert(tag.type != null);
    return tag.type.convertToStringKeys(_propsMap);
  }
}

/// A wrapper allowing a [TagNode]'s props to be accessed as fields.
@proxy
class Props {
  final Map<Symbol, dynamic> _props;

  const Props(this._props);

  noSuchMethod(Invocation inv) {
    if (inv.isGetter) {
      if (_props.containsKey(inv.memberName)) {
        return _props[inv.memberName];
      }
    }
    print("keys: ${_props.keys.join(", ")}");
    return super.noSuchMethod(inv);
  }
}
