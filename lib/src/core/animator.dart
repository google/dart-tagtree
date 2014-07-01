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
/// animation. The animator makes this decision in [shouldCut].
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

  /// Returns true if the renderer should cut to a new animation.
  /// stop playing this animation
  /// and cut to the next one. (The current Place will be unmounted and a
  /// new Place created for the next animation.)
  ///
  /// Otherwise, the current animation will continue playing.
  ///
  /// The default implementation cuts to the new animation if it's different,
  /// according to the '==' operator.
  bool shouldCut(Place<S> place, T nextTag, Animator nextAnim) => nextAnim != this;

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

  /// Returns true if the renderer shold cut to a new animation.
  /// If so, this tag will construct the new Place and render the new
  /// animation's first frame.
  /// Otherwise, the previous animation will continue and this
  /// tag will render the next frame.
  bool shouldCut(Place p) => false;
}

class _AnimatedTag<T extends AnimatedTag, S> extends Animator<T, S> {
  const _AnimatedTag();

  @override
  Place start(T firstTag) => firstTag.start();

  @override
  renderAt(Place p, T currentTag) => currentTag.renderAt(p);

  @override
  bool shouldCut(Place<S> place, T nextTag, Animator nextAnim) =>
      nextAnim != this || nextTag.shouldCut(place);
}
