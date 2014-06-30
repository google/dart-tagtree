part of core;

/// A callback for updating the DOM after the renderer is finished rendering
/// a frame of an animation.
/// See [Place.onRendered].
typedef OnRendered();

/// The place where an animation runs.
class Place<S> extends StateMachineMixin<S> {
  PlaceDelegate _delegate;

  Place(S firstState) {
    initStateMachine(firstState);
  }

  void mount(PlaceDelegate delegate) {
    this._delegate = delegate;
  }

  /// The animation that the renderer will cut to after [Animator.playWhile]
  /// returns false. This will be different from the current animation when
  /// the View or Theme for this place has changed.
  Animator get nextAnimator => _delegate.nextAnimator;

  void invalidate() => _delegate.invalidate();

  /// If this property is set when [Animator.renderAt] returns, the renderer will call
  /// the given function after updating the DOM.
  /// The callback can be used along with [DomPlace.ref] and [ElementView.ref] to
  /// get direct access to a DOM node.
  void set onRendered(OnRendered callback) {
    _delegate.onRendered = callback;
  }

  /// Called when an animation ends at a place.
  /// The DOM hasn't been removed yet.
  void unmount() {
    _delegate = null;
  }
}

abstract class PlaceDelegate {
  Animator get nextAnimator;
  void invalidate();
  void set onRendered(OnRendered callback);
}
