part of core;

/// A tag that renders differently depending on its size.
abstract class Resizable<T> implements Tag {
  T resize(num width, num height);
}

/// A tag container that, when rendered, will resize the tag that it encloses.
class ResizeZone extends Tag {
  final Resizable innerTag;

  ResizeZone(this.innerTag);

  @override
  Animator get animator => null; // special case
}