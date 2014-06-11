part of core;

/// A View is the configuration of a user interface that will be rendered as HTML.
///
/// Views have configuration properties ("props") that can normally be accessed
/// as final fields on the View subclass. These same properties are sometimes
/// accessible as a Map as well, via [props].
///
/// A prop may store an arbitrary Dart object. By convention it should be
/// immutable. A Viewer might use a prop's value to set an HTML attribute,
/// substitute data into a template, report an event (if it's a [HandlerFunc]),
/// or store a list of children (forming a "tag tree"). Declaring the type of a
/// prop (in the usual Dart way) is optional but recommended for clarity.
///
/// Unlike a tree of HTML elements in the DOM, a View is an immutable data
/// structure with no lifecycle or dependency on the browser. View subclasses
/// should be usable on client or server and can be freely shared or sent over
/// the network (provided that [propsImpl] is implemented and each property
/// can be encoded as JSON).
///
/// Also, Views can usually be Dart constants; unless there is a good reason, they
/// should have const constructors.
///
/// The [createViewer] method determines how the View will be rendered.
/// Normally this is done by looking up a function in the supplied [Theme].
///
/// You can implement a custom view by subclassing View to define the tag and
/// its props, and separately providing a [Template] or Widget for its
/// behavior.
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

  /// Creates the Viewer that will render this View to HTML.
  Viewer createViewer(Theme theme) {
    CreateViewerFunc create = theme[runtimeType];
    if (create == null) {
      throw "Theme ${theme.name} has no definition for ${runtimeType}";
    }
    return create();
  }

  /// Returns the contents of the view as a [PropsMap].
  /// This form is more suitable for reflective access and serializing to
  /// JSON.
  ///
  /// Not implemented by all View subclasses. If not implemented, it will throw
  /// an exception. A subclass can implement by overriding [propsImpl].
  PropsMap get props {
    var p = _propsCache[this];
    if (p == null) {
      p = new PropsMap(propsImpl);
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
  Map<String, dynamic> get propsImpl => throw "propsImpl isn't implemented for ${runtimeType}";

  @override
  String get jsonTag => throw "jsonTag not implemented";

  /// If non-null, the DOM element corresponding to this node will be placed
  /// in the ref when it's first rendered.
  /// (Only works client-side; see browser.Ref).
  get ref => null;

  static final _propsCache = new Expando<PropsMap>();
}

/// An alternate representation of a [View]'s fields.
class PropsMap extends UnmodifiableMapBase<String, dynamic> {
  final Map<String, dynamic> _map;

  PropsMap(this._map);

  /// Returns the key of each property.
  @override
  Iterable<String> get keys => _map.keys;

  /// Returns the value of a property.
  @override
  operator[](String key) => _map[key];
}
