part of core;

/// An Animator implements a [Tag] by rendering "shadow" tag trees
/// in response to events.
///
/// Animators are stateless and may be freely shared; a single
/// animator can render animations in multiple places at once.
/// The renderer chooses which Animator to use for a Tag by either
/// looking at the tag's [Tag.animator] property or by looking
/// up the animator in a [Theme].
///
/// Some animators just render a single frame, by substituting values
/// into a template. (See the [Template] subclass.) In that case,
/// a new frame won't be rendered until the input [Tag] or [Theme]
/// changes. Other animators keep animation-specific state in each
/// [Place] and render a new frame whenever this state changes.
///
/// Whenever a Tag or Theme changes, the renderer needs to decide
/// whether to continue playing the same animation or cut to a new
/// animation. The animator makes this decision in [playWhile].
abstract class Animator<T extends Tag, S> {

  /// Animators are stateless and should be const.
  const Animator();

  /// Starts a new animation.
  /// (Called automatically by the renderer.)
  /// Returns the Place object that the renderer will use to keep
  /// track of the animation.
  Place start(T firstTag);

  /// Renders one frame of an animation.
  /// (Called automatically by the renderer.)
  /// Returns the shadow tag tree to be rendered.
  Tag renderAt(Place<S> place, T currentTag);

  /// Returns true if the animation should continue to play.
  /// Otherwise, the renderer will cut to the next animation.
  /// (The current Place will be unmounted and a new Place created
  /// for the next animation.)
  ///
  /// The default implementation will work if subclass implements the '==' operator
  /// or if the animator is always constructed using a const constructor.
  bool playWhile(Place<S> place, T nextTag, Animator nextAnim) => nextAnim == this;

  /// Returns true if [renderAt] should be called after a tag change.
  /// Otherwise, the previous shadow will be reused, the possibly the DOM
  /// update will be skipped.
  bool shouldRender(Tag previousTag, Tag nextTag) => true;
}

/// Implements a Tag and its Animator at the same time.
/// (Useful for simple cases.)
abstract class AnimatedTag<S> extends Tag {
  const AnimatedTag();

  @override
  get animator => const _AnimatedTag();

  Place start();

  Tag renderAt(Place p);

  bool canRenderAt(Place p) => true;
}

class _AnimatedTag<T extends AnimatedTag, S> extends Animator<T, S> {
  const _AnimatedTag();

  @override
  Place start(T firstTag) => firstTag.start();

  @override
  renderAt(Place p, T currentTag) => currentTag.renderAt(p);

  @override
  bool playWhile(Place<S> place, T nextTag, Animator nextAnim) =>
      nextAnim == this && nextTag.canRenderAt(place);
}
