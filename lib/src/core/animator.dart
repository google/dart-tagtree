part of core;

/// An Animator renders shadow views in response to events.
/// Animators are stateless and may be freely shared, so that
/// they can render animations in multiple Places at once.
///
/// Some animators just substitute values into a template.
/// (See the [Template] subclass.) Stateful animations can be
/// implemented by storing and updating state in each Place.
///
/// The Animator to use is chosen based on a View and sometimes a Theme.
/// Whenever the View or Theme changes, the renderer checks whether it
/// needs to render another frame in the same animation or cut to the
/// next animation. This decision is made by [playWhile].
abstract class Animator<V extends View, S> {

  /// Animators are stateless and should be const.
  const Animator();

  Place makePlace(PlaceImpl impl, V firstView) {
    S first = firstState(firstView);
    if (first == null) {
      throw "firstState returned null for ${runtimeType}";
    }
    return new Place(impl, first);
  }

  /// Returns the animation's state for rendering its first frame.
  S firstState(V firstView);

  /// Returns the shadow view to be rendered in the given place.
  View renderFrame(Place<V,S> place);

  /// Returns true if the animation should continue to play.
  /// Otherwise, the renderer will cut to the next animation.
  /// (The current animation will stop and the next animation will
  /// start from the beginning.)
  bool playWhile(Place p) => p.nextAnimator == this;

  /// Called when an animation ends at a place.
  /// The DOM hasn't been removed yet.
  void onEnd(Place place) {}

  // Performance hooks for avoiding unnecessary rendering.

  /// Returns true if [renderFrame] should be called after a view change.
  /// Otherwise, the previous shadow will be reused, the possibly the DOM
  /// update will be skipped.
  bool needsRender(View previousView, View nextView) => true;
}

abstract class AnimatedView<S> extends View {
  const AnimatedView();

  @override
  get animator => const _AnimatedView();

  S get firstState;

  View renderFrame(Place p);
}

class _AnimatedView<V extends AnimatedView, S> extends Animator<V, S> {
  const _AnimatedView();

  @override
  firstState(V view) => view.firstState;

  @override
  renderFrame(Place p) => p.view.renderFrame(p);
}

