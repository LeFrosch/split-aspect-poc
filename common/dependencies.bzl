load(":common.bzl", "intellij_common")

# DependencyType enum; must match Dependency.DependencyType
_COMPILE_TIME = 0
_RUNTIME = 1

def _collect(ctx, names):
    """Returns the multiple attr as one depset. Filters out evertying except targets."""
    return depset(transitive = [depset(intellij_common.attr_as_label_list(ctx, name)) for name in names])

intellij_deps = struct(
    COMPILE_TIME = _COMPILE_TIME,
    RUNTIME = _RUNTIME,
    collect = _collect,
)
