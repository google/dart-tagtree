part of core;

/// A TagType is a JsonType that also allows the tag to be created from an invocation.
class TagType extends JsonType {

  final Symbol method;
  final Map<Symbol, String> params;

  const TagType({String jsonTag, JsonDecodeFunc fromMap, JsonEncodeFunc toMap,
    List<JsonType> deps: const [],
    this.method, this.params}) : super(jsonTag, toMap, fromMap, deps: deps);

  bool checked() {
    assert(deps != null);
    if (canDecodeInvocation) {
      assert(tagName != null); // for error reporting
      assert(params != null);
    }
    return true;
  }

  bool get canDecodeInvocation => method != null;

  /// Creates a tag from method call, for use within noSuchMethod.
  Tag fromInvocation(Invocation inv) {
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
    return decode(propsMap);
  }
}
