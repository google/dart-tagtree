part of core;

/// A Template renders a view by substituting another View.
abstract class Template<V extends View> extends Expander {
  const Template();

  render(V view);

  /// Templates don't need to be refreshed, so ignore the second argument.
  @override
  View expand(V view, _) => render(view);

  @override
  Expander chooseExpander(View next, Expander first) {
    // There is no state to preserve, so always use the template
    // that the view points to.
    return first;
  }

  @override
  bool shouldExpand(V before, V after) => true;

  // implement [CreateExpander].
  Template call() => this;
}

/// A Template that also serves as a state in a state machine.
abstract class TemplateState<V extends View> extends Expander {
  const TemplateState();

  View render(V view, Refresh refresh);

  @override
  View expand(V view, Refresh refresh) => render(view, refresh);

  /// Returns true if the given expander is the first state of the state machine
  /// that this state is a part of. (Used to determine whether a View points
  /// to the same state machine.)
  bool isFirstState(Expander e);

  @override
  Expander chooseExpander(View next, Expander first) {
    // Keep running this state machine unless the view points to a different start state.
    return isFirstState(first) ? this : first;
  }

  @override
  bool canReuseDom(Expander prev) => prev is TemplateState;
}

/// A view that renders itself using a template.
/// (It should be stateless; otherwise, use a regular View and a separate Expander for the state.)
abstract class TemplateView extends View {
  const TemplateView();

  Expander get defaultExpander => const _TemplateView();

  bool shouldRender(View prev) => true;

  View render();
}

class _TemplateView extends Template<TemplateView> {
  const _TemplateView();

  @override
  bool shouldExpand(TemplateView prev, TemplateView next) => next.shouldRender(prev);

  @override
  View render(input) => input.render();
}
