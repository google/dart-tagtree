part of json;

abstract class Jsonable {
  const Jsonable();

  /// Asserts that this object is well-formed.
  /// Called automatically before encoding the object, when in checked mode.
  bool checked() => true;

  JsonType get jsonType;
}

class JsonType<T extends Jsonable> {
  /// A tag used on the wire to identify instances encoded using this rule.
  /// (The tag must be unique within a [JsonRuleSet].)
  final String tagName;

  final JsonEncodeFunc _toJson;
  final JsonDecodeFunc _fromJson;

  const JsonType(this.tagName, this._toJson, this._fromJson);

  /// Returns true if this rule can encode the instance.
  bool appliesTo(instance) {
    if (instance is Jsonable) {
      return instance.jsonType == this;
    } else {
      return false;
    }
  }

  /// Returns the state of a Dart object as a JSON-encodable tree.
  /// The result may contain Jsonable instances and these will be
  /// encoded recursively.
  encode(T object) {
    assert(object.checked());
    var json = _toJson(object);
    assert(json != null);
    return json;
  }

  /// Given a tree returned by [encode], creates an instance.
  T decode(json, context) => _fromJson(json);
}

typedef JsonEncodeFunc(Jsonable object);

typedef Jsonable JsonDecodeFunc(jsonObject);
