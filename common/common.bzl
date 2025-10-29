def _struct(**kwargs):
    """A replacement for standard `struct` function that omits the fields with None value."""
    return struct(**{name: kwargs[name] for name in kwargs if kwargs[name] != None})

def _label_is_external(label):
    """Determines whether a label corresponds to an external artifact."""
    return label.workspace_root.startswith("external/")

def _label_to_string(label):
    """Stringifies a label, making sure any leading '@'s are stripped from main repo labels."""
    s = str(label)

    # If the label is in the main repo, make sure any leading '@'s are stripped so that tests are
    # okay with the fixture setups.
    return s.lstrip("@") if s.startswith("@@//") or s.startswith("@//") else s

def _attr_as_str(ctx, name):
    """Retunrs the attr as a string. Or the empty string if the attr is invalid."""
    value = getattr(ctx.rule.attr, name, None)

    if not value or type(value) != "str":
        return ""

    return value

def _attr_as_list(ctx, name):
    """Returns the attr as a list. Or the empty list if the attr is invalid."""
    value = getattr(ctx.rule.attr, name, None)

    if not value:
        return []

    if type(value) != "list":
        return [value]

    return value

def _attr_as_label_list(ctx, name):
    """Returns the attr as a list of targets. Fiters out everything except targets."""
    return [it for it in _attr_as_list(ctx, name) if type(it) == "Target"]

intellij_common = struct(
    struct = _struct,
    label_is_external = _label_is_external,
    label_to_string = _label_to_string,
    attr_as_str = _attr_as_str,
    attr_as_list = _attr_as_list,
    attr_as_label_list = _attr_as_label_list,
)
