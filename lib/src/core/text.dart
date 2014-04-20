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
class _Text extends _View {
  String value;
  _Text(String path, int depth, this.value) : super(_TextDef.instance, path, depth, null);
}

class _TextDef extends TagDef {
  static final instance = new _TextDef();
}

