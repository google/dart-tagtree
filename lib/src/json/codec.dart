part of json;

/// Registers a function so that it can be remotely called.
/// Returns a key to represent it.
typedef FunctionKey RegisterFunction(Function f);

/// A listener that receives calls made to a [RemoteFunction].
typedef void OnRemoteCall(FunctionCall call);

class TaggedJsonCodec extends Codec<dynamic, String> {
  Converter<dynamic, String> encoder;
  Converter<String, dynamic> decoder;

  TaggedJsonCodec(Iterable<JsonType> types,
      {RegisterFunction register, OnRemoteCall onCall}) {

    if (register == null) {
      register = _defaultRegister;
    }

    if (onCall == null) {
      onCall = _defaultOnCall;
    }

    var tagToType = <String, JsonType>{};
    for (var r in types) {
      assert(!tagToType.containsKey(r.tagName));
      tagToType[r.tagName] = r;
    }
    encoder = new TaggedJsonEncoder(tagToType, register);
    decoder = new TaggedJsonDecoder(tagToType, onCall);
  }

  static _defaultRegister(_) => throw "remote function registry not configured";

  static _defaultOnCall(FunctionCall call) {
    print("ignored remote function call: ${call}");
  }
}

/// Encodes a Dart object as a tree of tagged JSON.
///
/// The tree may contain values directly encodable as JSON (String, Map, List, and so on)
/// or instances of Jsonable.
class TaggedJsonEncoder extends Converter<dynamic, String> {
  final Map<String, JsonType> _types;
  final RegisterFunction _toKey;

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
  final OnRemoteCall onCall;

  TaggedJsonDecoder(this.types, this.onCall);

  convert(String json) => JSON.decode(json, reviver: (k,v) {
    v = _decode(v);
    if (v is FunctionKey) {
      return new RemoteFunction(v, onCall);
    } else {
      return v;
    }
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
          throw new UnknownTagException(tag);
        }
        assert(v.length == 2);
        Jsonable object = type.decode(v[1]);
        if (!object.checked()) {
          throw "check failed for deserialized object: ${object.runtimeType}";
        }
        return object;
      }
    } else {
      return v;
    }
  }
}

class UnknownTagException implements Exception {
  final String tag;
  const UnknownTagException(this.tag);
  toString() => "No type registered to decode tag: ${tag}";
}
