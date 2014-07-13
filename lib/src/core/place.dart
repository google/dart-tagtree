part of core;

typedef PlaceCallback(Place p);

/// The place where an animation runs.
///
/// A Place holds animation-specific data while an animation is playing.
/// To begin an animation, the renderer calls [Animator.start] to create a new
/// Place. Before rendering each frame, the animator should get the current state
/// from [Place.state].
///
/// Whenever an event handler gets or sets the [nextState] property, the
/// Place automatically requests a new animation frame. (A new frame can
/// also be requested by calling [step].)
class Place<S> extends StateMachineMixin<S> {

  /// Points to the renderer-specific implementation of this Place.
  /// Non-null while the Place is mounted.
  PlaceDelegate delegate;

  /// Called after each animation frame is rendered (when local).
  ///
  /// If the animation is running locally, the renderer will call this function
  /// after updating the DOM. The function can use a browser.Ref to get direct
  /// access to a DOM node.
  ///
  /// Not called if the animator is running outside the browser.
  PlaceCallback onRendered;

  /// Called after the last frame of the animation.
  /// The DOM hasn't been updated yet.
  PlaceCallback onCut;

  /// [Animator.start] should call this constructor.
  Place(S firstState) {
    initStateMachine(firstState);
  }

  /// Requests that the next frame of this animation be rendered.
  /// (Has no effect if the animation isn't running.)
  @override
  void step() {
    if (delegate != null) {
      delegate.requestFrame();
    }
  }
}

/// The implementation of a Place.
abstract class PlaceDelegate {
  void requestFrame();
}
