part of core;

/// Requests the next frame of an animation, using the given state.
///
/// If refresh is called more than once before the next animation frame
/// renders, all but the last frame will be skipped.
///
/// Each animation has a different refresh function. The renderer
/// calls [AnimFrame.expand] with the appropriate one to use.
typedef Refresh(nextState);

/// A function that directly updates the DOM after an animation frame is rendered.
/// See [AnimFrame.onRendered].
typedef OnRendered();

/// An animation implements a [View].
abstract class Animation<V extends View, S> {

  /// Animations other than Widgets are often constants.
  const Animation();

  S getFirstState(V v);

  /// Returns the shadow view to be rendered for the given input.
  /// Event handlers may call [refresh] to ask for another frame.
  View expand(View view, S state, Refresh refresh);

  /// Returns true if the current animation can continue to play after a View or
  /// Theme change.
  /// If true, the next View must be compatible.
  /// If false, the view's state will be lost and the new animation will
  /// start from the beginning.
  bool canPlay(View next, Animation nextAnim);

  // Performance hooks for avoiding unnecessary rendering.

  /// Returns true if the animation should render another frame.
  /// Otherwise, [expand] won't be called and the DOM won't be updated.
  /// (Note that the previous and next View may be the same.)
  bool shouldExpand(View previous, View next) => true;

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
