load(":common.bzl", "intellij_common")

# DependencyType enum; must match Dependency.DependencyType
_COMPILE_TIME = 0
_RUNTIME = 1

def _collect_from_toolchains(ctx, result, toolchain_types):
    """Collects dependencies from the toolchains context."""
    if not toolchain_types:
        return

    # toolchains attribute only available in Bazel 8+
    toolchains = getattr(ctx.rule, "toolchains", None)
    if not toolchains:
        return


    for toolchain_type in toolchain_types:
        if toolchain_type in toolchains:
            result.append(toolchains[toolchain_type][intellij_common.TargetInfo].owner)

def _collect_from_attributes(ctx, result, attributes):
    """Collects dependencies from the rule attributes."""
    if not attributes:
        return
    
    for name in attributes or []:
        result.extend(intellij_common.attr_as_label_list(ctx, name))

def _collect(ctx, attributes = None, toolchain_types = None):
    """Collects dependencies from multiple attributes and toolchains into one list."""
    result = []
    _collect_from_attributes(ctx, result, attributes)
    _collect_from_toolchains(ctx, result, toolchain_types)

    return depset(result)

intellij_deps = struct(
    COMPILE_TIME = _COMPILE_TIME,
    RUNTIME = _RUNTIME,
    collect = _collect,
)
