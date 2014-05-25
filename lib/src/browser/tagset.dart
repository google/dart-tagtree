part of browser;

class CustomTagSet extends core.HtmlTagSet {

  /// Defines a custom tag that's rendered by expanding a template.
  ///
  /// The render function should take a named parameter for each
  /// of the Tag's props.
  ///
  /// For increased performance, the optional shouldUpdate function may be
  /// used to avoid expanding the template when no properties have changed.
  ///
  /// If the custom tag should have internal state, use [defineWidget] instead.
  void defineTemplate({Symbol method, core.TagType type, core.ShouldUpdateFunc shouldUpdate,
    Function render}) {
    addTag(method, new core.TemplateTag(type: type, shouldUpdate: shouldUpdate, render: render));
  }

  /// Defines a custom Tag that has state.
  ///
  /// For custom tags that are stateless, use [defineTemplate] instead.
  void defineWidget({Symbol method, core.TagType type, core.CreateWidgetFunc make}) {
    addTag(method, new core.WidgetTag(type: type, make: make));
  }

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}