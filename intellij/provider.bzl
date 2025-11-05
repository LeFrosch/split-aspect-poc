IntelliJInfo = provider(
    doc = "Aggregation provider for IntelliJ aspect outputs and dependency edges.",
    fields = {
        "outputs": "dict[str, depset[File]] - Output groups emitted by this target (e.g., intellij-info).",
        "dependencies": "dict[int, depset[Target]] - Direct dependencies grouped by dependency type (see intellij_deps constants).",
    },
)

_IDE_INFO_FILE_OUTPUT_GROUP = "intellij-info"

def _create():
    """Creates an empty IntelliJInfo provider."""
    return IntelliJInfo(
        outputs = {},
        dependencies = {},
    )

def _update_depset_dict(it, other):
    """Merges two dictionaries defining multiple depsets."""
    for key in list(other):
        if key in it:
            it[key] = depset(transitive = [it[key], other[key]])
        else:
            it[key] = other[key]

def _update(it, other):
    """Updates this provider. Other must be either an IntellijInfo provider or a module provider."""
    _update_depset_dict(it.outputs, other.outputs)
    _update_depset_dict(it.dependencies, other.dependencies)

def _add_ide_info(it, file):
    """Updates this provider. Adds a intellij ide info file."""
    _update_depset_dict(it.outputs, {_IDE_INFO_FILE_OUTPUT_GROUP: depset([file])})

def _get_ide_info(it):
    """Gets the transitive intellij ide info file depset."""
    return it.outputs.get(_IDE_INFO_FILE_OUTPUT_GROUP, depset())

def _add_deps(it, group, deps):
    """Updates this provider. Adds all dependencies to the specified dependency group."""
    _update_depset_dict(it.dependencies, {group: deps})

intellij_info = struct(
    create = _create,
    update = _update,
    add_ide_info = _add_ide_info,
    get_ide_info = _get_ide_info,
    add_deps = _add_deps,
)
