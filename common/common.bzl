_IntelliJTargetInfo = provider(fields = ["owner", "key"])

def _struct(**kwargs):
    """A replacement for standard `struct` function that omits the fields with None value."""

    # TODO: this could be further improved with just `if kwargs[name]` to filter all default values
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
    """Returns the attr as a string. Or the empty string if the attr is invalid."""
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
    """Returns the attr as a list of targets. Filters out everything except targets."""
    return [it for it in _attr_as_list(ctx, name) if type(it) == "Target"]

def _intellij_info_aspect_impl(target, ctx):
    """Implementation for the target info aspect. Creates the key for the target."""
    key = _struct(
        aspect_ids = [it for it in ctx.aspect_ids if "_intellij_target_info_aspect" in it],
        label = intellij_common.label_to_string(target.label),
        configuration = getattr(ctx.configuration, "short_id", None),
    )

    return [intellij_common.TargetInfo(key = key, owner = target)]

# This is the first aspct run and any other aspect depends on it. Provides a key
# to uniquly reference targets between aspects.
_intellij_target_info_aspect = aspect(
    implementation = _intellij_info_aspect_impl,
    attr_aspects = ["*"],
    provides = [_IntelliJTargetInfo],
)

def _target_hash(target):
    """Creates a unique hash for the target based on its key."""
    key = target[_IntelliJTargetInfo].key
    parts = [key.label, getattr(key, "configuration", "")] + key.aspect_ids
    return hash(".".join(parts))

def _aspect(**kwargs):
    """A replacement for the standard `aspect` function that modifies some of the arguments."""
    requires = kwargs.pop("requires", [])
    requires.append(_intellij_target_info_aspect)

    return aspect(
        attr_aspects = ["*"],
        requires = requires,
        **kwargs
    )

intellij_common = struct(
    TargetInfo = _IntelliJTargetInfo,
    struct = _struct,
    aspect = _aspect,
    label_is_external = _label_is_external,
    label_to_string = _label_to_string,
    attr_as_str = _attr_as_str,
    attr_as_list = _attr_as_list,
    attr_as_label_list = _attr_as_label_list,
    target_hash = _target_hash,
)
