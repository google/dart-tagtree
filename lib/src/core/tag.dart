part of core;

/// A Tag is a request to display a UI element.
///
/// Each subtype of Tag represents a different kind of UI element.
/// Some tags are rendered as animated UI elements that move and react
/// to events. Despite that, the tags themselves are immutable and
/// their properties ("props") should be final fields.
///
/// A Tag may have other tags as children, forming a tag tree.
/// By convention, children are usually be stored in a field
/// named "inner".
///
/// Some tags represent single HTML elements; see [ElementTag]. These
/// tags need no implementation since they're specially handled by the
/// renderer.
///
/// Almost all other tags must be implemented by an [Animator].
/// A tag can be associated with its animator either using its
/// [animator] property or by putting the animator in a [Theme] in a
/// surrounding [ThemeZone] tag.
///
/// The [TemplateTag] and [AnimatedTag] subclasses are useful shortcuts
/// for implementing a Tag and its Animator at the same time.
///
/// A [JsonTag] can be serialized as JSON and sent over the network.
abstract class Tag {

  /// Subclasses of Tag should normally have a const constructor.
  const Tag();

  /// Asserts that the tag's props are valid. If so, returns true.
  ///
  /// This method exists so that the constructor can be const.
  /// When Dart is running in checked mode, this method will be
  /// called automatically before a Tag is rendered or sent over
  /// the network.
  bool checked() => true;

  /// Returns the default animator for this tag, which will be used
  /// when not overridden by a surrounding [ThemeZone].
  /// A null may be returned when there is no default, in which case
  /// rendering will fail unless the ThemeZone supplies an animator.
  Animator get animator;
}
