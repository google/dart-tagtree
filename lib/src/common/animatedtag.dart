part of common;

/// A tag that also implements its default animator.
abstract class AnimatedTag<S> extends Tag {
  const AnimatedTag();

  @override
  get animator => const _AnimatedTag();

  Place start();

  Tag renderAt(Place p);

  /// Returns true if the renderer should call [start] and begin a new
  /// animation. Otherwise, the current animation will continue with the
  /// same [Place].
  bool shouldRestart(Place p) => false;
}

class _AnimatedTag<T extends AnimatedTag, S> extends Animator<T, S> {
  const _AnimatedTag();

  @override
  Place start(T firstTag) => firstTag.start();

  @override
  renderAt(Place p, T currentTag) => currentTag.renderAt(p);

  @override
  bool shouldCut(Place<S> place, T nextTag, Animator nextAnim) =>
      nextAnim != this || nextTag.shouldRestart(place);
}