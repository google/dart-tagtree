part of core;

/// Requests that a rendered view be expanded again, with a new expander.
///
/// If refresh is called more than once before the next animation frame,
/// the argument from the last call will be used.
///
/// Each Refresh function implicitly targets one rendered view. The renderer
/// passes the appropriate function to [Expander.expand].
typedef Refresh(Expander next);

/// A function that directly updates the DOM after the tagtree renderer is done.
/// See [Expander.onRendered].
typedef OnRendered();

/// Expands a view to a "shadow" that will be rendered instead.
/// Expanders can be stateless (a simple template) or stateful.
abstract class Expander {

  /// Templates and simple view states can be constants.
  const Expander();

  /// Returns the shadow view to be rendered in place of the given input.
  /// Event handlers may call [refresh] to trigger a re-render.
  View expand(View input, Refresh refresh);

  /// Chooses the expander for the next frame in an animation.
  ///
  /// The renderer calls this method whenever the input View or
  /// Theme changes. It will call the expander given by the most
  /// recent call to [Refresh], or the last rendered expander if
  /// Refresh wasn't called.
  ///
  /// The [first] expander is the one that the renderer would use
  /// for the first frame of an animation. (That is, returning it
  /// will start fresh, dropping all view state.)
  ///
  /// Subclasses should return [first] if they are stateless or
  /// some other expander (possibly _this_) if they wish to preserve
  /// view state after the view changes.
  Expander chooseExpander(View next, Expander first);

  // Performance hooks for avoiding unnecessary rendering.

  /// Returns true if the renderer can reuse the previous expander's DOM for
  /// the next animation frame. Otherwise, the renderer will discard the DOM
  /// and view state, starting a new animation.
  bool canReuseDom(Expander lastRendered) => lastRendered.runtimeType == this.runtimeType;

  /// Returns true if the renderer should call [expand] before updating the DOM.
  /// Otherwise, the renderer will reuse the shadow View from the previous frame
  /// and skip updating the DOM entirely.
  /// Called only if canReuseDom returned true.
  bool shouldExpand(View prev, View next) => true;

  // Hooks needed for direct DOM access.

  /// If not null, the renderer calls this function after updating the DOM.
  /// This callback can be used along with [ElementView.ref] to get direct
  /// access to a DOM node.
  OnRendered get onRendered => null;

  /// Called when the expander is no longer needed.
  /// The DOM hasn't been removed yet.
  void willUnmount() {}
}
