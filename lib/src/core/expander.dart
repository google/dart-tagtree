part of core;

/// A function provided by the renderer that the expander should call
/// when it needs to be rendered in the next animation frame.
typedef RenderNeeded();

/// A function provided by the expander that the renderer should call
/// when the DOM is ready.
typedef OnRendered();

/// Expands a view to a "shadow" View that will be rendered instead.
/// Expanders can be stateless (a template) or stateful (a widget).
///
/// For a template, only [expand] needs to be implemented. A simple
/// state machine may be implemented by overriding [nextExpander]
/// to return another expander representing the new state. Or, a widget
/// may have internal mutable state and call the supplied [RenderNeeded]
/// function when it needs to be expanded again.
abstract class Expander {

  /// Templates and simple view states can be constants.
  const Expander();

  /// Returns the shadow view to be rendered in place of the given input.
  View expand(View input);

  /// Returns the expander to be used for the next animation frame.
  /// The renderer calls this method whenever the input View changes,
  /// before calling [expand] again.
  ///
  /// Subclasses should override to return "this" if the expander
  /// is to be reused with the next View. Otherwise, the current expander
  /// will be unmounted. The returned expander will be mounted and used
  /// instead.
  Expander nextExpander(View nextView, Expander defaultValue) => defaultValue;

  // Lifecycle hooks (relevant only for mutable expanders).

  /// Initializes the expander.
  /// The renderer will call [mount] before any other method.
  void mount(RenderNeeded r) {}

  /// Called when the expander is no longer needed.
  void unmount() {}

  // Performance hooks for avoiding unnecessary rendering.

  /// Returns true if the renderer can reuse the previous expander's DOM for
  /// the next animation frame. Otherwise, the renderer will discard the DOM
  /// and re-create it.
  bool canReuseDom(Expander prev) => prev == this;

  /// Returns true if the renderer should call [expand] before updating the DOM.
  /// Otherwise, the renderer will reuse the shadow View from the previous frame
  /// and skip updating the DOM entirely.
  /// Called only if canReuseDom returned true.
  bool shouldExpand(View prev, View next) => true;

  // Direct DOM access.

  /// Returns a function that the renderer will call after updating the DOM.
  /// This callback can be used along with [ElementView.ref] to get direct
  /// access to a DOM node.
  ///
  /// If null, the callback will be skipped.
  OnRendered get onRendered => null;
}
