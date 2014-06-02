part of core;

/// A TaggedNode is a node in an abstract syntax tree that will be rendered to HTML.
/// A tree of TaggedNodes ("tag tree") is somwhat like a tree of HTML elements with
/// the addition of special nodes for templates and widgets.
///
/// Nodes have no built-in behavior. To render a tag tree to HTML, there must be a
/// rule for each tag determining how it will be rendered.
abstract class TaggedNode implements Jsonable {

  /// The constructor of each TaggedNode should be const.
  /// It should take a named parameter for each property.
  const TaggedNode();

  /// The unique key for any rules determining this tag's behavior.
  /// The tag is also used in the node's JSON encoding.
  String get tag;

  @override
  String get jsonTag => tag;

  /// Constructs a property map containing every field.
  /// A property may contain JSON data (extended to include
  /// other TagNodes) or a [HandlerFunc].
  ///
  /// A node's children may be stored in any prop. By convention,
  /// they are usually stored in the "inner" prop.
  Map<String, dynamic> get propsMap {
    throw "propsMap isn't implemented for ${tag}";
  }

  /// Returns an object that should be populated with the rendered
  /// version of this node.
  get ref => null;

  Props get asProps {
    var p = _propsCache[this];
    if (p == null) {
      p = new Props(this);
      _propsCache[p] = p;
    }
    return p;
  }

  static final _propsCache = new Expando<Props>();
}

/// An alternate representation of a TagNode
/// (Used to send it over the network.)
class Props {
  final String tag;
  final Map<String, dynamic> propsMap;
  Props(TaggedNode node) : tag = node.tag, propsMap = node.propsMap;

  /// Returns the key of each prop.
  Iterable<String> get keys => propsMap.keys;

  /// Returns the value of a property.
  operator[](String key) => propsMap[key];
}
