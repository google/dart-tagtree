part of core;

/// A tag that can be encoded as tagged JSON.
abstract class JsonTag extends Tag implements Jsonable {
  const JsonTag();

  /// Remotely-rendered tags usually get their implementation from a [Theme].
  Animator get animator => null;

  /// Subclasses must supply a TagMaker. By convention, the maker property
  /// should point to a static constant named "$maker".
  TagMaker get jsonType;

  /// Returns the tag's props as a [PropsMap].
  ///
  /// Throws an exception if not implemented. Subclasses should implement
  /// this method by implementing [jsonType] and [TagMaker.toProps].
  PropsMap get props {
    var p = _propsCache[this];
    if (p == null) {
      assert(checked());
      if (jsonType.toJson == null) {
        throw "TagMaker for ${runtimeType} doesn't have an encoder function";
      }
      p = new PropsMap(jsonType.toJson(this));
      _propsCache[p] = p;
    }
    return p;
  }

  static final _propsCache = new Expando<PropsMap>();
}

/// A PropsMap provides an alternate representation of a [JsonTag]'s fields.
class PropsMap extends UnmodifiableMapBase<String, dynamic> {
  final Map<String, dynamic> _map;

  PropsMap(this._map);

  @override
  Iterable<String> get keys => _map.keys;

  @override
  operator[](String key) => _map[key];
}
