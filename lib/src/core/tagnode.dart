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
///
/// To construct a node, use a [TagSet] or a subclass of [Tag].
class TagNode {
  final Tag tag;
  final Map<Symbol, dynamic> propMap;
  Props _props;

  TagNode._raw(this.tag, this.propMap);

  /// Provides access to the tag's props as a map.
  operator[](Symbol key) => propMap[key];

  /// Provides access to the tag's props as fields.
  Props get props {
    if (_props == null) {
      _props = new Props(propMap);
    }
    return _props;
  }
}

class JsonableNode extends TagNode implements Jsonable {
  JsonableNode._raw(Tag def, Map<Symbol, dynamic> propMap) : super._raw(def,  propMap);
  String get jsonTag => tag.type.name;
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
