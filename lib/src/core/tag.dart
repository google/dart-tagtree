part of core;

/// A Tag is a request to display a UI element.
///
/// Each subtype of Tag represents a different kind of UI element.
/// Tags are immutable and their properties ("props") should be
/// final fields.
///
/// A Tag may have other tags as children, forming a tag tree. By convention,
/// children should normally be stored in a field named "inner".
///
/// Some tags represent single HTML elements; see [ElementTag].
/// Other tags are implemented by an [Animator]. A tag can be
/// associated with its animator either by overriding the [animator] property
/// or by adding the animator to a [Theme] in a surrounding [ThemeZone].
/// (The Theme's mapping takes priority when a theme is in scope.)
///
/// The [TemplateTag] and [AnimatedTag] subclasses are useful shortcuts
/// for implementing a Tag and its Animator at the same time.
///
/// Tag objects have no lifecycle or dependency on the browser and are
/// often usable on client or server. If a Tag implements the [maker]
/// property with a suitable [TagMaker], it can be serialized to JSON
/// and sent over the network.
abstract class Tag implements Jsonable {

  /// Subclasses of Tag should normally have a const constructor.
  const Tag();

  /// Asserts that the tag's props are valid. If so, returns true.
  ///
  /// This method exists so that the constructor can be const.
  /// When Dart is running in checked mode, this method will be
  /// called automatically before a Tag is rendered or sent over
  /// the network.
  bool checked() => true;

  /// Returns the default animator for this tag, which will be used
  /// when not overridden by a surrounding [ThemeZone].
  /// A null may be returned when there is no default, in which case
  /// the ThemeTag must supply an animator.
  Animator get animator;

  /// Returns the TagMaker for this tag.
  ///
  /// Throws an exception by default. Subclasses should implement this property
  /// if needed to support reflection (via "props") and JSON encoding.
  TagMaker get maker {
    throw "maker property not implemented for ${runtimeType}";
  }

  /// Returns the tag's props as a [PropsMap].
  ///
  /// Throws an exception if not implemented. Subclasses should implement
  /// this method by implementing [maker] and [TagMaker.toProps].
  PropsMap get props {
    var p = _propsCache[this];
    if (p == null) {
      assert(checked());
      if (maker.toProps == null) {
        throw "TagMaker for ${runtimeType} doesn't have a toProps function";
      }
      p = maker.toProps(this);
      _propsCache[p] = p;
    }
    return p;
  }

  @override
  String get jsonTag => maker.jsonTag;

  static final _propsCache = new Expando<PropsMap>();
}

/// A PropsMap provides an alternate representation of a [Tag]'s fields.
class PropsMap extends UnmodifiableMapBase<String, dynamic> {
  final Map<String, dynamic> _map;

  PropsMap(this._map);

  @override
  Iterable<String> get keys => _map.keys;

  @override
  operator[](String key) => _map[key];
}

/// A function for creating a Tag from its JSON properties.
typedef Tag MapToTag(Map<String, dynamic> propsMap);

/// A function for converting a Tag to a PropsMap containing its JSON properties.
///
/// For a tag to be serializable, the properties should contain JSON data
/// (including other [Jsonable] nodes) or a [HandlerFunc].
typedef PropsMap TagToProps(Tag tag);

/// A TagMaker provides additional ways to create a Tag.
///
/// The [fromMap] method creates a tag from a map containing its properties.
///
/// The [fromInvocation] method can be used to create a tag from within
/// [noSuchMethod].
///
/// By convention, the TagMaker for "Foo" should be in a constant named "$Foo".
/// Multiple TagMakers can be collected into a [TagSet].
class TagMaker {
  /// For decoding and encoding JSON
  final String jsonTag;
  final MapToTag fromMap;
  final TagToProps toProps;
  final Iterable<HandlerType> handlers;

  /// For decoding an Invocation
  final Symbol method;
  final Map<Symbol, String> params;

  const TagMaker({this.jsonTag, this.fromMap, this.toProps, this.handlers: const [],
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
