load("//common:common.bzl", "intellij_common")

def _create(root_path, relative_path, is_source, is_external):
    """Creates creates an ArtifactLocation proto."""

    return intellij_common.struct(
        relative_path = relative_path,
        root_path = root_path,
        is_source = is_source,
        is_external = is_external,
    )

def _from_file(file):
    """Creates an ArtifactLocation proto from a File."""
    if file == None:
        return None

    relative_path = _strip_external_workspace_prefix(file.short_path)
    relative_path = _strip_root_path(relative_path, file.root.path)

    root_path = file.path[:-(len("/" + relative_path))]

    return _create(
        root_path = root_path,
        relative_path = relative_path,
        is_source = file.is_source,
        is_external = intellij_common.label_is_external(file.owner),
    )

def _from_list(targets):
    """Converts a list of targets to a list of artifact locations."""
    return [
        _from_file(f)
        for target in targets
        for f in target.files.to_list()
    ]

def _from_attr(ctx, name):
    """Converts a rule attribute to a list of artifact locations. Rule attribute should be of type label list."""
    return _from_list(getattr(ctx.rule.attr, name, []))

def _strip_root_path(path, root_path):
    """Strips the root_path from the path."""
    if root_path and path.startswith(root_path + "/"):
        return path[len(root_path + "/"):]
    else:
        return path

def _strip_external_workspace_prefix(path):
    """Strips '../workspace_name/' prefix."""
    if path.startswith("../"):
        return "/".join(path.split("/")[2:])
    else:
        return path

artifact_location = struct(
    create = _create,
    from_file = _from_file,
    from_list = _from_list,
    from_attr = _from_attr,
)
