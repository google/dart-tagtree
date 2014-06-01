part of core;

/// An ElementTag renders a node as an HTML element.
///
/// The TagType's name will be used the name of the HTML element, and the type's
/// property names will be used as the name of each attribute.
///
/// The following attributes have special handling:
///   #inner or #innerHtml should hold the element's children.
///   #value or #defaultValue should hold the value of a form input.
class ElementTag {
  // If the type is non-null, nodes with this tag will have their structure checked,
  // and they can be encoded as JSON.
  final TagType type;

  const ElementTag(this.type);

  /// A subclass hook to assert that the Tag itself is well-formed.
  /// (This check isn't done in the constructor so that it can be const.)
  bool checked() {
    assert(type != null);
    return true;
  }

  /// A subclass hook to assert that a node's properties are well-formed.
  bool checkProps(ElementNode node) {
    assert(node["inner"] == null || node["innerHtml"] == null);
    assert(node["value"] == null || node["defaultValue"] == null);
    return true;
  }

  /// Checks that a node is well-formed.
  /// Called automatically on new nodes when Dart is running in checked mode.
  bool checkNode(ElementNode node) {
    assert(checked());
    if (type != null) {
      assert(type.checkPropKeys(node));
    }
    assert(checkProps(node));
    return true;
  }

  /// Returns the type for checking a property with the given key (if available).
  PropType getPropType(String propKey) => type == null ? null : type.propsByName[propKey];
}
