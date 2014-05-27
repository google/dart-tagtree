part of widget;

typedef Widget CreateWidgetFunc();

/// Creates tags that are rendered as widgets.
class WidgetTag extends Tag {
  final CreateWidgetFunc make;
  const WidgetTag({TagType type, this.make}) : super(type);

  @override
  bool checked() {
    assert(make != null);
    return true;
  }
}
