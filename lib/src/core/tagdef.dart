part of core;

/// A Tag acts as a node constructor and also determines the behavior of the
/// nodes it creates.
abstract class Tag {
  final TagType type; // may be null when the tag is only used locally.

  const Tag(TagType this.type);

  TagNode makeNode(Map<Symbol, dynamic> props) {
    assert(checkTag());
    if (type != null) {
      assert(type.checkPropKeys(props));
    }
    assert(checkProps(props));
    if (type != null && type.name != null) {
      return new JsonableNode._raw(this, props);
    } else {
      return new TagNode._raw(this, props);
    }
  }

  /// Subclass hook to check that the tag is well-formed.
  /// (Not done in the constructor so that it can be const.)
  bool checkTag() => true;

  /// Subclass hook to check a node's properties.
  bool checkProps(Map<Symbol, dynamic> props) => true;

  /// Implement call() to call makeNode() with any named arguments.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod && inv.memberName == #call) {
      if (!inv.positionalArguments.isEmpty) {
        throw "positional arguments not supported for node creation";
      }
      return makeNode(inv.namedArguments);
    }
    return super.noSuchMethod(inv);
  }
}

/// A tag with no behavior. (Nodes cannot be rendered, only serialized.)
class RemoteTag extends Tag {
  const RemoteTag(TagType type) : super(type);

  @override
  bool checkTag() {
    assert(type != null);
    return true;
  }
}

/// A tag that renders a node as an HTML element.
class ElementTag extends Tag {

  const ElementTag(TagType type) : super(type);

  /// The name used when rendering the tag as HTML.
  String get tagName => type.name;

  @override
  bool checkTag() {
    assert(type != null);
    return true;
  }

  @override
  bool checkProps(Map<Symbol, dynamic> props) {
    var inner = props[#inner];
    assert(inner == null || props[#innerHtml] == null);
    assert(inner == null || inner is String || inner is TagNode || inner is Iterable);
    assert(props[#value] == null || props[#defaultValue] == null);
    return true;
  }

  String getAttributeName(Symbol propKey) {
    var prop = type.propsBySymbol[propKey];
    if (prop is AttributeType) {
      return prop.name;
    } else {
      return null;
    }
  }

  bool isHandler(Symbol propKey) => type.propsBySymbol[propKey] is HandlerPropType;
}

/// Creates tags that are rendered by expanding a template.
class TemplateTag extends Tag {
  final ShouldUpdateFunc shouldUpdate;
  final Function render;

  /// Defines a custom tag that's rendered by expanding a template.
  ///
  /// The render function should take a named parameter for each of the node's props.
  ///
  /// For increased performance, the optional shouldUpdate function may be used to
  /// avoid expanding the template when no properties have changed.
  ///
  /// If the custom tag should have internal state, use a WidgetDef instead.
  const TemplateTag({TagType type, this.render, this.shouldUpdate}) : super(type);

  @override
  bool checkTag() {
    assert(render != null);
    return true;
  }

  TagNode renderProps(Map<Symbol, dynamic> props) {
    return Function.apply(render, [], props);
  }

  static _alwaysUpdate(p, next) => true;
}

typedef bool ShouldUpdateFunc(Props p, Props next);

/// Creates tags that are rendered as widgets.
class WidgetTag extends Tag {
  final CreateWidgetFunc make;
  const WidgetTag({TagType type, this.make}) : super(type);

  @override
  bool checkTag() {
    assert(make != null);
    return true;
  }
}

typedef Widget CreateWidgetFunc();

