part of core;

/// A Tag constructs nodes and determines their behavior.
abstract class Tag {
  // If null, there is no type checking and the tag can't be serialized.
  final TagType type;

  const Tag(this.type);

  /// Subclass hook to assert that the Tag is well-formed.
  /// (Not done in the constructor so that it can be const.)
  bool checked() => true;

  /// Subclass hook to assert that a node's properties are well-formed.
  bool checkProps(TagNode node) => true;

  bool checkNode(TagNode node) {
    assert(checked());
    if (type != null) {
      assert(type.checkPropKeys(node));
    }
    assert(checkProps(node));
    return true;
  }

  /// Returns the type associated with one of the tag's properties.
  PropType getPropType(Symbol propKey) => type == null ? null : type.propsBySymbol[propKey];

  /// Implement call() to create the node with any named arguments.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod && inv.memberName == #call) {
      if (!inv.positionalArguments.isEmpty) {
        throw "positional arguments not supported for node creation";
      }
      return new TagNode(this, inv.namedArguments);
    }
    return super.noSuchMethod(inv);
  }
}

/// A tag with no behavior. (Nodes cannot be rendered, only serialized.)
class RemoteTag extends Tag {
  const RemoteTag(TagType type) : super(type);

  @override
  bool checked() {
    assert(type != null);
    return true;
  }
}

/// A tag that renders a node as an HTML element.
class ElementTag extends Tag {

  const ElementTag(TagType type) : super(type);

  @override
  bool checked() {
    assert(type != null);
    return true;
  }

  @override
  bool checkProps(TagNode node) {
    var inner = node[#inner];
    assert(inner == null || node[#innerHtml] == null);
    assert(inner == null || inner is String || inner is TagNode || inner is Iterable);
    assert(node[#value] == null || node[#defaultValue] == null);
    return true;
  }
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
  bool checked() {
    assert(render != null);
    return true;
  }

  static _alwaysUpdate(p, next) => true;
}

typedef bool ShouldUpdateFunc(Props p, Props next);

/// Creates tags that are rendered as widgets.
class WidgetTag extends Tag {
  final CreateWidgetFunc make;
  const WidgetTag({TagType type, this.make}) : super(type);

  @override
  bool checked() {
    assert(make != null);
    return true;
  }
}

typedef Widget CreateWidgetFunc();

