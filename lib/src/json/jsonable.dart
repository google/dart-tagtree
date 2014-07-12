part of json;

abstract class Jsonable {
  const Jsonable();

  /// Asserts that this object is well-formed.
  /// Called automatically before encoding the object, when in checked mode.
  bool checked() => true;

  JsonType get jsonType;
}

class JsonType extends JsonRule {
  final JsonEncodeFunc toJson;
  final JsonDecodeFunc fromJson;
  const JsonType(String tag, this.toJson, this.fromJson) : super(tag);

  @override
  bool appliesTo(instance) {
    if (instance is Jsonable) {
      return instance.jsonType == this;
    } else {
      return false;
    }
  }

  @override
  encode(object) {
    assert(object.checked());
    var json = toJson(object);
    assert(json != null);
    return json;
  }

  @override
  decode(json, context) => fromJson(json, context);
}

typedef JsonEncodeFunc(Jsonable object);

typedef Jsonable JsonDecodeFunc(jsonObject, decodeContext);

class JsonableFinder implements TagFinder<Jsonable> {
  const JsonableFinder();

  @override
  bool appliesToType(instance) => instance is Jsonable;

  @override
  String getTag(Jsonable instance) => instance.jsonType.tagName;
}
