part of core;

/// A function that the expander should call when it's "dirty" and needs to be re-rendered.
typedef RenderNeeded();

/// A function that the renderer should call when the DOM is ready.
typedef OnRendered();

/// Expands a view to its "shadow" for rendering an animation frame.
/// Expanders can be stateless (a template) or stateful (a widget).
/// For a template, only [expand] needs to be implemented.
abstract class Expander {

  /// Templates can be constants.
  const Expander();

  /// Initializes the expander.
  /// The renderer will call [mount] before any other method.
  void mount(RenderNeeded r) {}

  /// Returns true if the renderer can reuse this expander for another animation frame.
  ///
  /// Otherwise, the renderer will discard this expander and use the [next] one instead.
  /// It will also discard the DOM and re-create it. For best efficiency, expanders should
  /// be reused when possible.
  bool canReuse(Expander next) => next == this;

  /// Returns true if the renderer should call [expand] when rendering the next frame.
  ///
  /// Otherwise, the renderer will reuse the shadow View from the previous frame
  /// and will often skip updating the DOM entirely. For best efficiency, expand()
  /// calls should be skipped when unnecessary.
  bool shouldExpand(View prev, View next) => true;

  /// Returns the shadow view to be rendered in place of the given input.
  View expand(View input);

  /// Returns a function that the renderer should call after updating the DOM.
  /// (If null, it will be skipped.)
  OnRendered get onRendered => null;

  /// Called when the expander is no longer needed.
  void unmount() {}
}
