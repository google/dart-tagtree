part of core;

/// Requests the next frame of an animation, after updating its state.
///
/// The passed-in step function will be applied to the animation's state
/// before rendering.
///
/// If refresh is called more than once before the next animation frame
/// renders, all the step functions will be applied in order before
/// rendering. This is to avoid dropping events if they happen faster
/// than the frame rate.
///
/// Each animation instance has its own refresh function. The renderer
/// calls [Animation.expand] with the appropriate function to
/// use that that animation.
typedef Refresh(Step step);

/// A function that takes an old state and returns a new state.
typedef Step(input);

/// A callback for updating the DOM after the renderer is finished rendering
/// a frame of an animation.
/// See [Animation.onRendered].
typedef OnRendered();

/// An Animation implements a [View] as a series of shadow views.
/// Animations may contain state that changes in response to events.
/// Alternatively, a stateless Animation can act as a simple template.
/// (See the [Template] subclass.)
///
/// A animation depends on an input View and Theme. Whenever the View or
/// Theme changes, the renderer checks whether it needs to render another
/// shadow View or cut to the next Animation.
abstract class Animation<V extends View, S> {

  /// Animations other than Widgets are often constants.
  const Animation();

  /// Returns the animation's state for rendering its first frame.
  S getFirstState(V firstView);

  /// Returns the shadow view to be rendered.
  /// The shadow may contain event handlers that call [refresh] to
  /// re-render with a new animation state.
  View expand(View input, S state, Refresh refresh);

  /// Returns true if the animation should continue to play.
  /// If so, the next View  must be compatible.
  /// Otherwise, the renderer will cut to the next animation.
  /// The current animation will stop and the next animation will
  /// start from the beginning.
  bool shouldPlay(View next, Animation nextAnim);

  // Performance hooks for avoiding unnecessary rendering.

  /// Returns true if [expand] should be called to create a new shadow
  /// for the next animation frame. Otherwise, the previous shadow will
  /// be reused, the possibly the DOM update will be skipped.
  /// (Note that the previous and next View or state may be the same.)
  bool shouldExpand(View previousView, S previousState, View nextView, S nextState) => true;

  // Hooks needed for direct DOM access.

  /// If not null, the renderer calls this function after updating the DOM.
  /// This callback can be used along with [ElementView.ref] to get direct
  /// access to a DOM node.
  OnRendered get onRendered => null;

  /// Called when the expander is no longer needed.
  /// The DOM hasn't been removed yet.
  void willUnmount() {}
}

class AnimFrame {
  final View view;
  const AnimFrame(this.view);
}
