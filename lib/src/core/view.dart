part of core;

/// A View is a node in a tree that will be rendered to HTML.
///
/// Each View has a [type] that plays a role similar to an HTML tag.
/// A tree of views (a "tag tree") is somewhat like a tree of HTML elements.
/// However, some views are rendered by expanding a template or by creating
/// a Widget (based on a Theme).
///
/// Unlike a tree of DOM Elements, a tag tree is an immutable data structure
/// with no state, lifecycle, or browser dependencies. Since Views have
/// structure but no behavior, tag trees can be freely shared and sent over
/// the network. They can also be constants. However, once rendered, some
/// Views turn into Widgets, which contain mutable state and can react to
/// events.
///
/// You can implement a custom view by subclassing View to define its tag and
/// properties, and separately providing a template or Widget for its behavior.
abstract class View implements Jsonable {

  /// The default constructor of each View should be const.
  /// It should take a named parameter for each property.
  const View();

  /// Asserts that a View's properties are valid.
  /// (Not done in the constructor so that it can be const.)
  /// Subclasses should implement this method if they have any constraints.
  /// When Dart is running in checked mode, this method will automatically be
  /// called before a View is rendered or sent over the network.
  bool checked() => true;

  /// The key that will be used to bind this view to a [Viewer].
  /// It may be any type that works as a Map key.
  /// By default it's the [runtimeType].
  get type => runtimeType;

  /// Returns the tag and properties of the node, in the form suitable
  /// for reflective access and for sending it across the network.
  PropsMap get props {
    var p = _propsCache[this];
    if (p == null) {
      p = new PropsMap(type, propsImpl);
      _propsCache[p] = p;
    }
    return p;
  }

  /// Constructs the property map needed for [props] to work.
  ///
  /// A property may contain JSON data (including other Jsonable nodes)
  /// or a [HandlerFunc].
  ///
  /// A node's children may be stored in any field. By convention,
  /// they are usually stored in its "inner" field.
  Map<String, dynamic> get propsImpl => throw "propsImpl isn't implemented for ${type}";

  @override
  String get jsonTag => throw "jsonTag not implemented";

  /// If non-null, the DOM element corresponding to this node will be placed
  /// in the ref when it's first rendered.
  /// (Only works client-side; see browser.Ref).
  get ref => null;

  static final _propsCache = new Expando<PropsMap>();
}

/// An alternate representation of a [View].
class PropsMap extends UnmodifiableMapBase<String, dynamic> {
  final type;
  final Map<String, dynamic> _map;

  PropsMap(this.type, this._map);

  /// Returns the key of each property.
  @override
  Iterable<String> get keys => _map.keys;

  /// Returns the value of a property.
  @override
  operator[](String key) => _map[key];
}
