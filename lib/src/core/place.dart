part of core;

/// A callback for updating the DOM after the renderer is finished rendering
/// a frame of an animation.
/// See [Place.onRendered].
typedef OnRendered();

/// The place where an animation runs.
/// The default implementation delegates to another Place.
class Place<V extends View, S> extends StateMachineMixin<S> {
  PlaceImpl _delegate;

  Place(S firstState) {
    initStateMachine(firstState);
  }

  void mount(PlaceImpl delegate) {
    this._delegate = delegate;
  }

  V get view => _delegate.view;

  /// The animation that the renderer will cut to after [Animation.playWhile]
  /// returns false. This will be different from the current animation when
  /// the View or Theme for this place has changed.
  Animator get nextAnimator => _delegate.nextAnimator;

  void invalidate() => _delegate.invalidate();

  /// If this property is set when [Animator.renderFrame] returns, the renderer will call
  /// the given function after updating the DOM.
  /// The callback can be used along with [DomPlace.ref] and [ElementView.ref] to
  /// get direct access to a DOM node.
  void set onRendered(OnRendered callback) {
    _delegate.onRendered = callback;
  }
}

abstract class PlaceImpl {
  View get view;
  Animator get nextAnimator;
  void invalidate();
  void set onRendered(OnRendered callback);
}
