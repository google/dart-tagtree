part of core;

/// An Animator generates a stream of output tags from a stream of input tags.
/// The input and output streams are called animations.
///
/// An animation may contain other animations, all playing at the same time.
/// This happens when a renderer pipes part of one animator's output stream
/// into another animator. These pipelines form a tree structure that divide
/// up a web page into nested animations. The outer animation controls the lifetime
/// of the inner animations by deciding whether to render each tag in a new
/// frame.
///
/// Animations don't run at a fixed frame rate. Instead, each animator generates
/// frames as needed. The outer animation may be paused (not generating frames)
/// or moving. When it generates a new frame, the renderer will send a [Tag] to each
/// downstream animator, and they will usually render new frames as well. (But this
/// may be skipped; see [shouldRender].)
///
/// An inner animation may generate new frames on its own when the outer animation
/// is paused, in response to events handled entirely within the inner animation. In
/// this case, [Place.nextState] or [Place.step] should be used to trigger a new frame.
abstract class Animator<T extends Tag, S> {

  /// Animators are normally const since they contain no animation-specific state.
  /// (If not const, the == operator should be implemented, since it's used by the default
  /// implementation of [shouldCut].)
  const Animator();

  /// Starts a new animation.
  ///
  /// The animator should create a new Place for keeping track of any animation-specific
  /// state.
  Place start(T firstInputTag);

  /// Renders one frame of an animation.
  ///
  /// Creates an output tag tree that should be rendered in place of the [inputTag].
  ///
  /// A single animator can render frames from multiple animations that are all playing
  /// at the same time. Therefore, animators must read any animation-specific state from
  /// the provided [place]. Any event handlers in the generated output tree should write
  /// to the same [place].
  ///
  /// The [inputTag] could be different for each frame. This happens when an animation
  /// runs inside another animation and the outer animation renders a new frame.
  Tag renderAt(Place<S> place, T inputTag);

  /// Returns true if [renderAt] should be called after a tag change.
  ///
  /// Otherwise, the previous shadow tree will be reused.
  /// (This improves performance since updating the DOM can often
  /// be skipped altogether.)
  bool shouldRender(Tag previousTag, Tag nextTag) => true;

  /// Returns true if the renderer should cut to a new animation.
  ///
  /// If true, the current Place will be discarded after calling [Place.onCut],
  /// and a new Place created by calling the next animation's [start] method.
  /// Otherwise, the current animation will continue playing with the new input tag.
  ///
  /// The default implementation cuts to the next animation when the renderer chooses
  /// a different animator (based on ==) for the next tag.
  bool shouldCut(Place<S> place, T nextInputTag, Animator nextAnim) => this != nextAnim;
}

