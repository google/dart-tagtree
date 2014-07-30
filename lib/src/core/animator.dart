part of core;

/// An Animator generates a stream of output tags from a stream of inputs.
/// The output stream is called an animation and each tag in the stream is a frame.
///
/// Each animation plays a similar role to a view in a typical user interface library.
/// Like a view, an animation typically covers a part of the screen (its bounds).
///
/// Animations may be nested inside other animations, similar to a view hierarchy.
/// An Animator controls the lifetimes of the inner animations by choosing
/// whether or not to render a Tag in each frame.
///
/// Each animation runs at a different, variable frame rate. Typically, a new outer
/// frame will cause a new inner frame to be rendered, but this can be skipped;
/// see [shouldRender].) An inner animation may generate a frame that doesn't correspond
/// to an outer frame using [Place.nextState] or [Place.step].
abstract class Animator<IN, S> {

  /// Animators are normally const since they contain no animation-specific state.
  /// (If not const, the == operator should be implemented, since it's used by the default
  /// implementation of [shouldCut].)
  const Animator();

  /// Starts a new animation.
  ///
  /// Each call to start should return a different Place, which will be used to
  /// keep track of any animation-specific state.
  Place start(IN firstInput);

  /// Generates one frame of an animation.
  ///
  /// A single animator can render frames from multiple animations that are all playing
  /// at the same time. Therefore, animators must read any animation-specific state from
  /// the provided [place]. Any event handlers in the output frame should also use the
  /// provided [place].
  ///
  /// The [input] may be the same or different than the previous frame in the same
  /// animation, depending on whether the outer animation is running faster or slower.
  Tag renderAt(Place<S> place, IN input);

  /// Returns true if [renderAt] should be called after the input animation generated a
  /// new frame.
  ///
  /// Otherwise, the previous output will be reused.
  /// (This improves performance since updating the DOM can often be skipped altogether.)
  bool shouldRender(IN previousInput, IN nextInput) => true;

  /// Returns true if the renderer should cut to another animation.
  ///
  /// If true is returned, the current Place will be discarded after calling [Place.onCut],
  /// and a new Place created by calling the next animation's [start] method.
  /// Otherwise, the current animation will continue playing with the new input.
  ///
  /// The default implementation cuts to the next animation as soon as it's different,
  /// based on the == operator.
  bool shouldCut(Place<S> place, IN input, nextInput, Animator nextAnim) =>
      this != nextAnim;
}
