load("//common:artifact_location.bzl", "artifact_location")
load("//common:common.bzl", "intellij_common")
load("//common:provider.bzl", "intellij_provider")
load("//common:target_key.bzl", "target_key")

IntelliJInfo = provider(fields = ["outputs", "key"])

def _get_build_file_location(ctx):
    """Creates an ArtifactLocation proto representing a location of a given BUILD file."""
    return artifact_location.create(
        ctx.label.workspace_root,
        ctx.label.package + "/BUILD",
        True,
        intellij_common.label_is_external(ctx.label),
    )

def _merge_output_groups(a, b):
    """Merges to dictionaries defining multiple output groups."""
    result = dict(a)

    for key in list(b):
        if key in result:
            result[key] = depset(transitive = [result[key], b[key]])
        else:
            result[key] = b[key]

    return result

def _get_dependency_output_groups(ctx):
    """Collects and merges all intellij output groups from all dependencies."""
    result = dict()

    for name in dir(ctx.rule.attr):
        for dep in intellij_common.attr_as_label_list(ctx, name):
            if not IntelliJInfo in dep:
                continue

            result = _merge_output_groups(result, dep[IntelliJInfo].outputs)

    return result

def _write_ide_info(target, ctx, info, key):
    """Serializes and writes the info struct to the intellij-info.txt file."""

    # bazel allows target names differing only by case, so append a hash to support case-insensitive file systems
    file_name = "%s-%s.intellij-info.txt" % (target.label.name, target_key.hash(key))

    file = ctx.actions.declare_file(file_name)
    ctx.actions.write(file, proto.encode_text(struct(**info)))

    return {"intellij-info-generic": depset([file])}

def _collect_info(target, ctx, key):
    """Collects and joins information collected from language specific providers."""
    if not intellij_provider.any(target):
        return {}

    tags = ctx.rule.attr.tags

    if "no-ide" in tags:
        return []

    ide_info = {
        "build_file_artifact_location": _get_build_file_location(ctx),
        "kind_string": ctx.rule.kind,
        "key": key,
        "tags": tags,
    }

    outputs = {}
    for name, provider in intellij_provider.ALL.items():
        if not provider in target or not target[provider].present:
            continue

        ide_info[name] = target[provider].value
        outputs = _merge_output_groups(outputs, target[provider].outputs)

    return _merge_output_groups(outputs, _write_ide_info(target, ctx, ide_info, key))

def _aspect_impl(target, ctx):
    key = target_key.create(ctx, target)

    outputs = _collect_info(target, ctx, key)
    outputs = _merge_output_groups(outputs, _get_dependency_output_groups(ctx))

    return [IntelliJInfo(outputs = outputs, key = key), OutputGroupInfo(**outputs)]

intellij_info_aspect = aspect(
    implementation = _aspect_impl,
    attr_aspects = ["*"],
    required_aspect_providers = [[it] for it in intellij_provider.ALL.values()],
    provides = [IntelliJInfo],
)
