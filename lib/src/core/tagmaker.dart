part of core;

/// A TagMaker provides additional ways to create a [JsonTag].
///
/// The [fromJson] method creates a tag from a map containing its properties.
///
/// The [fromInvocation] method can be used to create a tag from within
/// [noSuchMethod].
///
/// Multiple TagMakers can be collected into a [TagSet].
class TagMaker extends JsonType {
  final Iterable<HandlerType> handlers;

  /// For decoding an Invocation
  final Symbol method;
  final Map<Symbol, String> params;

  const TagMaker({String jsonTag, JsonDecodeFunc fromMap, JsonEncodeFunc toProps, this.handlers: const [],
    this.method, this.params}) : super(jsonTag, toProps, fromMap);

  bool checked() {
    assert(handlers != null);
    if (canDecodeJson) {
      assert(fromJson != null);
    }
    if (canDecodeInvocation) {
      assert(tagName != null); // for error reporting
      assert(params != null);
      assert(toJson != null);
    }
    return true;
  }

  bool get canDecodeJson => tagName != null;

  bool get canDecodeInvocation => method != null;

  JsonTag fromInvocation(Invocation inv) {
    if (!inv.positionalArguments.isEmpty) {
      throw "positional arguments not supported when creating tags";
    }
    assert(canDecodeInvocation);
    var propsMap = <String, dynamic>{};
    for (Symbol name in inv.namedArguments.keys) {
      var propKey = params[name];
      if (propKey == null) {
        throw "no property found for ${name} in ${tagName}";
      }
      propsMap[propKey] = inv.namedArguments[name];
    }
    return fromJson(propsMap, null);
  }
}
