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
/// calls [Animation.renderFrame] with the appropriate function to
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
  S firstState(V firstView);

  /// Returns the shadow view to be rendered in the given place.
  View renderFrame(Place<V,S> place);

  /// Returns true if the animation should continue to play.
  /// Otherwise, the renderer will cut to the next animation.
  /// (The current animation will stop and the next animation will
  /// start from the beginning.)
  bool playWhile(Place p) => p.nextAnimation == this;

  // Performance hooks for avoiding unnecessary rendering.

  /// Returns true if [renderFrame] should be called after a view change.
  /// Otherwise, the previous shadow will be reused, the possibly the DOM
  /// update will be skipped.
  bool needsRender(View previousView, View nextView) => true;

  // Hooks needed for direct DOM access.

  /// If not null, the renderer calls this function after updating the DOM.
  /// This callback can be used along with [ElementView.ref] to get direct
  /// access to a DOM node.
  OnRendered get onRendered => null;

  /// Called when the expander is no longer needed.
  /// The DOM hasn't been removed yet.
  void willUnmount() {}
}

/// The place where an animation runs.
abstract class Place<V extends View, S> {
  V get view;
  S get state;

  /// The animation that the renderer will cut to after [Animation.playWhile]
  /// returns false. This will be different from the current animation when
  /// the View or Theme for this place has changed.
  Animation get nextAnimation;

  void nextFrame(Step);
}

class AnimFrame {
  final View view;
  const AnimFrame(this.view);
}
