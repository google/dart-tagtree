part of json;

abstract class Jsonable {
  String get jsonTag;
}

class JsonableFinder implements TagFinder<Jsonable> {
  const JsonableFinder();

  @override
  bool appliesToType(instance) => instance is Jsonable;

  @override
  String getTag(Jsonable instance) => instance.jsonTag;
}
