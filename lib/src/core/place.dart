part of core;

/// A callback for updating the DOM after the renderer is finished rendering
/// a frame of an animation.
/// See [Place.onRendered].
typedef OnRendered();

typedef PlaceCallback(Place p);

/// The place where an animation runs.
class Place<S> extends StateMachineMixin<S> {
  PlaceDelegate _delegate;
  PlaceCallback onMount;
  PlaceCallback onUnmount;

  Place(S firstState) {
    initStateMachine(firstState);
  }

  void mount(PlaceDelegate delegate) {
    this._delegate = delegate;
    if (onMount != null) {
      onMount(this);
    }
  }

  @override
  void invalidate() {
    if (_delegate != null) {
      _delegate.invalidate();
    }
  }

  /// If this Place is a server-side animation that's being displayed remotely,
  /// wraps the given event handler so that it can be included in a tag tree
  /// that will be sent over the network. (Otherwise does nothing.)
  HandlerFunc handler(HandlerFunc h) => _delegate.wrapHandler(h);

  /// If this property is set when [Animator.renderAt] returns, the renderer will call
  /// the given function after updating the DOM.
  /// The callback can be used along with browser.Ref and [ElementTag.ref] to
  /// get direct access to a DOM node.
  void set onRendered(PlaceCallback callback) {
    _delegate.onRendered = callback;
  }

  /// Called when an animation ends at a place.
  /// The DOM hasn't been removed yet.
  void unmount() {
    if (onUnmount != null) {
      onUnmount(this);
    }
    _delegate = null;
  }
}

abstract class PlaceDelegate {
  HandlerFunc wrapHandler(HandlerFunc h);
  void invalidate();
  void set onRendered(PlaceCallback callback);
}
