load("//common:common.bzl", "intellij_common")

def _is_intellij_aspect_id(id):
    """Heuristic to filter intellij info aspect ids"""
    return "%intellij_" in id and id.endswith("_info_aspect")

def _create(ctx, target):
    """Returns a TargetKey proto struct from a target."""
    return intellij_common.struct(
        aspect_ids = [it for it in ctx.aspect_ids if not _is_intellij_aspect_id(it)],
        label = intellij_common.label_to_string(target.label),
        configuration = getattr(ctx.configuration, "short_id", None),
    )

def _hash(key):
    """Creates a unique hash based on the target key."""
    parts = [key.label, getattr(key, "configuration", "")] + key.aspect_ids
    return hash(".".join(parts))

target_key = struct(
    create = _create,
    hash = _hash,
)
