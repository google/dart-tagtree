part of json;

/// A FunctionKey points to the implementation of a remote function.
class FunctionKey extends Jsonable {
  final int frameId;
  final int id;

  FunctionKey(this.frameId, this.id);

  @override
  get jsonType => $jsonType;

  static const $jsonType = const JsonType("handler", toJson, fromJson);
  static toJson(FunctionKey h) => [h.frameId, h.id];
  static fromJson(array) {
    if (array is List && array.length >= 2) {
      return new FunctionKey(array[0], array[1]);
    } else {
      throw "can't decode info FunctionKey: ${array.runtimeType}";
    }
  }
}

/// A proxy for a remote function.
/// (It is callable, but should be wrapped in a function on deserialization
/// to store in variables that have a Function type.)
class RemoteFunction {
  final FunctionKey key;
  final OnRemoteCall onCall;
  RemoteFunction(this.key, this.onCall);

  @override
  noSuchMethod(Invocation inv) {
    if (inv.isMethod && inv.memberName == #call) {
      if (inv.namedArguments.isNotEmpty) {
        throw "remote functions don't support named parameters";
      }
      FunctionCall call = new FunctionCall(key, inv.positionalArguments);
      onCall(call);
    } else {
      super.noSuchMethod(inv);
    }
  }
}

/// A FunctionCall contains arguments to be delivered to the implementation of a [RemoteFunction].
class FunctionCall extends Jsonable {
  final FunctionKey key;
  final List<Jsonable> args;

  FunctionCall(this.key, this.args);

  @override
  get jsonType => $jsonType;

  static const $jsonType = const JsonType("call", toJson, fromJson);

  static toJson(FunctionCall call) => [call.key.frameId, call.key.id, call.args];

  static fromJson(array) {
    if (array is List && array.length >= 3) {
      var key = new FunctionKey(array[0], array[1]);
      return new FunctionCall(key, array[2]);
    } else {
      throw "can't decode into FunctionCall: ${array.runtimeType}";
    }
  }
}
