IntelliJInfo = provider(fields = ["outputs", "dependencies"])

def _create():
    """Creates an empty IntelliJInfo provider."""
    return IntelliJInfo(
        outputs = {},
        dependencies = {},
    )

def _update_depset_dict(it, other):
    """Merges to dictionaries defining multiple depsets."""
    for key in list(other):
        if key in it:
            it[key] = depset(transitive = [it[key], other[key]])
        else:
            it[key] = other[key]

def _update(it, other):
    """Updates this provider. Other must be either an IntellijInfo provider or a module provider."""
    _update_depset_dict(it.outputs, other.outputs)
    _update_depset_dict(it.dependencies, other.dependencies)

def _add_file(it, group, file):
    """Updates this provider. Adds a file to the specified output group."""
    _update_depset_dict(it.outputs, {group: depset([file])})

def _add_deps(it, group, deps):
    """Updates this provider. Adds all dependencies to the specified dependency group."""
    _update_depset_dict(it.dependencies, {group: deps})

intellij_info = struct(
    create = _create,
    update = _update,
    add_file = _add_file,
    add_deps = _add_deps,
)
