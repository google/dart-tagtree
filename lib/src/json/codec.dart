part of json;

/// Registers a function so that it can be remotely called.
/// Returns a key to represent it.
typedef Jsonable FunctionToKey(Function f);

/// Converts each function key into a callable function.
/// Returns other values unchanged.
typedef MakeCallable(Jsonable functionKey);

class TaggedJsonCodec extends Codec<dynamic, String> {
  Converter<dynamic, String> encoder;
  Converter<String, dynamic> decoder;

  TaggedJsonCodec(Iterable<JsonType> types,
      {FunctionToKey toKey: _defaultToKey, MakeCallable makeCallable: _defaultMakeCallable}) {
    var tagToType = <String, JsonType>{};
    for (var r in types) {
      assert(!tagToType.containsKey(r.tagName));
      tagToType[r.tagName] = r;
    }
    encoder = new TaggedJsonEncoder(tagToType, toKey);
    decoder = new TaggedJsonDecoder(tagToType, makeCallable);
  }

  static _defaultToKey(_) => throw "can't encode function";
  static _defaultMakeCallable(v) => v;
}

/// Encodes a Dart object as a tree of tagged JSON.
///
/// The tree may contain values directly encodable as JSON (String, Map, List, and so on)
/// or instances of Jsonable.
class TaggedJsonEncoder extends Converter<dynamic, String> {
  final Map<String, JsonType> _types;
  final FunctionToKey _toKey;

  TaggedJsonEncoder(this._types, this._toKey);

  String convert(object) {
    StringBuffer out = new StringBuffer();
    _encodeTree(out, object);
    return out.toString();
  }

  void _encodeTree(StringBuffer out, v) {

    if (v is Function) {
      v = _toKey(v);
    }

    if (v == null || v is bool || v is num || v is String) {
      out.write(JSON.encode(v));
      return;
    }

    if (v is List) {
      out.write("[0");
      for (var item in v) {
        out.write(",");
        _encodeTree(out, item);
      }
      out.write("]");
      return;
    }

    if (v is Map) {
      Map<String, Object> m = v;
      out.write("{");
      bool first = true;
      v.forEach((String key, Object value) {
        if (!first) {
          out.write(',');
        }
        out.write("${JSON.encode(key)}:");
        _encodeTree(out, value);
        first = false;
      });
      out.write("}");
      return;
    }

    JsonType type = _getType(v);
    if (type == null) {
      // encoding will probably fail, but give the default encoder a chance.
      out.write(JSON.encode(v));
      return;
    }

    assert(_checkApplies(type, v));
    var data = type.encode(v);
    out.write("[${JSON.encode(type.tagName)},");
    _encodeTree(out, data);
    out.write("]");
  }

  bool _checkApplies(JsonType type, v) {
    if (!type.appliesTo(v)) {
      throw "JsonType doesn't apply: ${type} to ${v}";
    }
    return true;
  }

  /// Returns the type or null if there is none.
  JsonType _getType(Jsonable v) {
    String tag = v.jsonType.tagName;

    var out = _types[tag];
    if (out == null) {
      print("type not found for tag: ${tag}");
    }
    return out;
  }
}

/// Decodes tagged JSON into Dart objects.
///
/// Lists in the JSON code are treated specially based on the
/// first item, which is used as a tag. If the tag is a 0 then
/// the remaining items form the actual list. Otherwise, the
/// decoder looks up the appropriate type to decode the list.
class TaggedJsonDecoder extends Converter<String, dynamic> {
  final Map<String, JsonType> types;
  final MakeCallable makeCallable;

  TaggedJsonDecoder(this.types, this.makeCallable);

  convert(String json) => JSON.decode(json, reviver: (k,v) {
    v = _decode(v);
    return makeCallable(v);
  });

  _decode(v) {
    if (v is List) {
      var tag = v[0];
      if (tag == 0) {
        v.remove(0);
        return v;
      } else {
        var type = types[tag];
        if (type == null) {
          throw "no type for tag: ${tag}";
        }
        assert(v.length == 2);
        return type.decode(v[1]);
      }
    } else {
      return v;
    }
  }
}
