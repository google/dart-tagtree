part of core;

/// A plain text view.
///
/// The framework needs to find the corresponding DOM element using a query on a
/// data-path attribute, so the text is actually rendered inside a <span>.
/// (We can't support mixed-content HTML directly and instead use a list of Elt and
/// Text views as the closest equivalent.)
///
/// However, if the parent's "inner" property is just a string, it's handled as a
/// special case and the Text class isn't used.
class Text extends View {
  String value;
  Text(this.value, {Ref ref}): super(ref);

  Props get props => new Props({
    #value: value
  });

  void doMount(StringBuffer out) {
    // need to surround with a span to support incremental updates to a child
    out.write("<span data-path=${_path}>${HTML_ESCAPE.convert(value)}</span>");
  }

  void doUnmount(_) {}

  void traverse(callback) => callback(this);

  bool canUpdateTo(View other) => (other is Text);

  void update(Text nextVersion, ViewTree tree, NextFrame frame) {
    print("refresh Text: ${_path}");

    if (nextVersion == null || value == nextVersion.value) {
      return; // no internal state to update
    }
    value = nextVersion.value;
    frame
        ..visit(_path)
        ..setInnerText(value);
  }
}
