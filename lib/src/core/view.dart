part of core;

/// A View specifies an animation that will be rendered as stream of HTML elements.
///
/// The View itself is only a set of configuration properties ("props").
/// Views are normally immutable and their props should be final fields.
///
/// A View's implementation is an animation. A View can be associated with
/// its animation either by overriding [animation] to point to the first
/// frame of the animation, or by using a [Theme] to specify the first
/// frame. (The Theme takes priority if both ways are used.)
///
/// Not all views animate; in that case, there is only a first frame and
/// the view acts as a template. (See [TemplateView].) Some views render
/// as single HTML elements. (See [ElementView].)
///
/// View objects have no lifecycle or dependency on the browser and should be
/// usable on client or server. If [propsImpl] is implemented, a View can
/// be serialized and sent over the network.
abstract class View implements Jsonable {

  /// Most Views can be stored as Dart constants.
  const View();

  /// Asserts that the View's props are valid. If so, returns true.
  ///
  /// (Not done in the constructor so that it can be const.)
  /// When Dart is running in checked mode, this method will automatically be
  /// called before a View is rendered or sent over the network.
  bool checked() => true;

  /// Returns the animation for this View when not overridden by a Theme.
  Animation get animation;

  /// Returns the view's props as a [PropsMap].
  ///
  /// Throws an exception if not implemented. Subclasses should implement
  /// this method by overriding [propsImpl].
  PropsMap get props {
    var p = _propsCache[this];
    if (p == null) {
      assert(checked());
      p = new PropsMap(propsImpl);
      _propsCache[p] = p;
    }
    return p;
  }

  /// Constructs the property map needed for [props] to work.
  ///
  /// For a View to be serializable, its props should contain JSON data
  /// (including other [Jsonable] nodes) or a [HandlerFunc].
  ///
  /// A node's children may be stored in any field. By convention,
  /// they are usually stored in its "inner" field.
  Map<String, dynamic> get propsImpl => throw "propsImpl isn't implemented for ${runtimeType}";

  @override
  String get jsonTag => throw "jsonTag not implemented";

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
