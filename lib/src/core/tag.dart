part of core;

/// A Tag is a request to display a UI element.
///
/// Each subtype of Tag represents a different kind of UI element.
/// Tags are immutable and their properties ("props") should be
/// final fields.
///
/// A Tag may have other tags as children, forming a tag tree. By convention,
/// children should normally be stored in a property named "inner".
///
/// Some tags represent single HTML elements. (See [ElementTag]. Other
/// tags are implemented by an [Animator]. A tag can be associated with
/// its animator either by overriding the [animator] property or by adding
/// the animator to a [Theme]. (The Theme's mapping takes priority when
/// a theme is used.)
///
/// For convenience, the [TemplateTag] and [AnimatedTag] subclasses can be used
/// as shortcuts to implement a tag and its animator at the same time.
///
/// Tag objects have no lifecycle or dependency on the browser and are often
/// usable on client or server. If a tag implements [propsImpl], it can
/// be serialized to JSON and sent over the network.
abstract class Tag implements Jsonable {

  /// Most tags can used as constants.
  const Tag();

  /// Asserts that the tag's props are valid. If so, returns true.
  ///
  /// This method exists so that the constructor can be const.
  /// When Dart is running in checked mode, this method will be
  /// called automatically before the tag is rendered or sent over
  /// the network.
  bool checked() => true;

  /// Returns the animator for this tag, when not overridden by a Theme.
  Animator get animator;

  /// Returns the tag's props as a [PropsMap].
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
  /// For a tag to be serializable, its props should contain JSON data
  /// (including other [Jsonable] nodes) or a [HandlerFunc].
  ///
  /// By convention, a tag's children are usually stored in its "inner" field.
  Map<String, dynamic> get propsImpl => throw "propsImpl isn't implemented for ${runtimeType}";

  @override
  String get jsonTag => throw "jsonTag not implemented";

  static final _propsCache = new Expando<PropsMap>();
}

/// A function for creating a Tag from its JSON properties.
typedef Tag MakeTagFunc(Map<String, dynamic> propsMap);

/// A TagMaker provides other ways to create one type of Tag.
///
/// The [fromMap] method creates a tag from a map containing its properties.
/// The [fromInvocation] method can be used to create a tag from within
/// [noSuchMethod].
///
/// By convention, the TagMaker for "Foo" should be in a constant named "$Foo".
/// (Perhaps someday this will be an annotation?)
///
/// Multiple TagMakers can be collected into a [TagSet].
class TagMaker {
  /// For decoding JSON
  final String jsonTag;
  final MakeTagFunc fromMap;
  final Iterable<HandlerType> handlers;

  /// For decoding an Invocation
  final Symbol method;
  final Map<Symbol, String> params;

  const TagMaker({this.jsonTag, this.fromMap, this.handlers: const [],
    this.method, this.params});

  bool checked() {
    assert(handlers != null);
    if (canDecodeJson) {
      assert(fromMap != null);
    }
    if (canDecodeInvocation) {
      assert(jsonTag != null); // for error reporting
      assert(params != null);
      assert(fromMap != null);
    }
    return true;
  }

  bool get canDecodeJson => jsonTag != null;

  bool get canDecodeInvocation => method != null;

  Tag fromInvocation(Invocation inv) {
    if (!inv.positionalArguments.isEmpty) {
      throw "positional arguments not supported when creating tags";
    }
    assert(canDecodeInvocation);
    var propsMap = <String, dynamic>{};
    for (Symbol name in inv.namedArguments.keys) {
      var propKey = params[name];
      if (propKey == null) {
        throw "no property found for ${name} in ${jsonTag}";
      }
      propsMap[propKey] = inv.namedArguments[name];
    }
    return fromMap(propsMap);
  }
}

/// A PropsMap provides an alternate representation of a [Tag]'s fields.
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
