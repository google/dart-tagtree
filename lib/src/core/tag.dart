part of core;

/// A Tag determines the structure and behavior of a node in a tag tree.
abstract class Tag {
  // If the type is non-null, nodes with this tag will have their structure checked,
  // and they can be encoded as JSON.
  final TagType type;

  const Tag(this.type);

  /// A subclass hook to assert that the Tag itself is well-formed.
  /// (This check isn't done in the constructor so that it can be const.)
  bool checked() => true;

  /// A subclass hook to assert that a node's properties are well-formed.
  bool checkProps(TagNode node) => true;

  /// Checks that a node is well-formed.
  /// Called automatically on new nodes when Dart is running in checked mode.
  bool checkNode(TagNode node) {
    assert(checked());
    if (type != null) {
      assert(type.checkPropKeys(node));
    }
    assert(checkProps(node));
    return true;
  }

  /// Returns the type for checking a property with the given key (if available).
  PropType getPropType(Symbol propKey) => type == null ? null : type.propsBySymbol[propKey];

  /// Implements call() to create a new node with this tag.
  /// The caller should send the node's props as named parameters.
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

/// A TemplateTag renders a node by expanding a template.
///
///  The render function should declare a named parameter for each of the node's props.
///
/// For increased performance, the optional shouldUpdate function may be used to
/// avoid expanding the template when no properties have changed.
class TemplateTag extends Tag {
  final ShouldRenderFunc shouldRender;
  final Function render;

  const TemplateTag({TagType type, this.render, this.shouldRender}) : super(type);

  @override
  bool checked() {
    assert(render != null);
    return true;
  }

  static _alwaysUpdate(p, next) => true;
}

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(TagNode before, TagNode after);

/// An ElementTag renders a node as an HTML element.
///
/// The TagType's name will be used the name of the HTML element, and the type's
/// property names will be used as the name of each attribute.
///
/// The following attributes have special handling:
///   #inner or #innerHtml should hold the element's children.
///   #value or #defaultValue should hold the value of a form input.
class ElementTag extends Tag {

  const ElementTag(TagType type) : super(type);

  @override
  bool checked() {
    assert(type != null);
    return true;
  }

  @override
  bool checkProps(TagNode node) {
    assert(node[#inner] == null || node[#innerHtml] == null);
    assert(node[#value] == null || node[#defaultValue] == null);
    return true;
  }
}