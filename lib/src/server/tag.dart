part of server;

/// A RemoteTag has no behavior, but can be sent over the socket connection.
class RemoteTag extends core.Tag {
  const RemoteTag(core.TagType type) : super(type);

  @override
  bool checked() {
    assert(type != null);
    return true;
  }
}
