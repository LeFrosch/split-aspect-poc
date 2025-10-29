def _struct(**kwargs):
    """A replacement for standard `struct` function that omits the fields with None value."""
    return struct(**{name: kwargs[name] for name in kwargs if kwargs[name] != None})

def _label_is_external(label):
    """Determines whether a label corresponds to an external artifact."""
    return label.workspace_root.startswith("external/")

intellij_common = struct(
    struct = _struct,
    label_is_external = _label_is_external,
)
