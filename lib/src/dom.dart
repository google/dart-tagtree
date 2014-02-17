part of core;

/// Encapsulates all operations used to update the DOM to the next frame.
abstract class NextFrame {

  /// Creates the DOM for a top-level View in a given container.
  /// The domQuery should refer to exactly one HtmlElement.
  void mount(String domQuery, String html);

  /// Clears any references to the DOM node with the given path.
  void detachElement(String path);

  /// Visits the element at the given path. Other methods act on the current element.
  void visit(String path);

  void replaceElement(String html);

  void setAttribute(String key, String value);

  void removeAttribute(String key);

  void setInnerHtml(String html);

  void setInnerText(String text);

  void replaceChildElement(int index, String newHtml);

  void addChildElement(String childHtml);

  void removeChild(int index);
}
