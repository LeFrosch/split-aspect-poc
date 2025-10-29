load("//common:provider.bzl", "intellij_provider")

IntelliJInfo = provider(fields = ["outputs"])

def _stringify_label(label):
    """Stringifies a label, making sure any leading '@'s are stripped from main repo labels."""
    s = str(label)

    # If the label is in the main repo, make sure any leading '@'s are stripped so that tests are
    # okay with the fixture setups.
    return s.lstrip("@") if s.startswith("@@//") or s.startswith("@//") else s

def _merge_output_groups(a, b):
    """Merges to dictionaries defining multiple output groups."""
    result = dict(a)

    for key in list(b):
        if key in result:
            result[key] = depset(transitive = [result[key], b[key]])
        else:
            result[key] = b[key]

    return result

def _dependency_output_groups(ctx):
    """Collects and merges all intellij output groups from all dependencies."""
    result = dict()

    for name in dir(ctx.rule.attr):
        value = getattr(ctx.rule.attr, name)
        if not value:
            continue

        if type(value) != "list":
            value = [value]

        for dep in value:
            if type(dep) != "Target" or not IntelliJInfo in dep:
                continue

            result = _merge_output_groups(result, dep[IntelliJInfo].outputs)

    return result

def _write_ide_info(target, ctx, info):
    """Serializes and writes the info struct to the intellij-info.txt file."""

    # bazel allows target names differing only by case, so append a hash to support case-insensitive file systems
    file_name = "%s-%s.intellij-info.txt" % (target.label.name, str(hash(target.label.name)))

    file = ctx.actions.declare_file(file_name)
    ctx.actions.write(file, proto.encode_text(struct(**info)))

    return {"intellij-info-generic": depset([file])}

def _collect_info(target, ctx):
    """Collects and joins information collected from language specific providers."""
    if not intellij_provider.any(target):
        return {}

    ide_info = {}
    outputs = {}

    ide_info["label"] = _stringify_label(target.label)
    ide_info["kind"] = ctx.rule.kind
    ide_info["configuration_hash"] = getattr(ctx.configuration, "short_id", "")

    for name, provider in intellij_provider.ALL.items():
        if not provider in target or not target[provider].present:
            continue

        ide_info[name] = target[provider].value
        outputs = _merge_output_groups(outputs, target[provider].outputs)

    return _merge_output_groups(outputs, _write_ide_info(target, ctx, ide_info))

def _aspect_impl(target, ctx):
    outputs = _collect_info(target, ctx)
    outputs = _merge_output_groups(outputs, _dependency_output_groups(ctx))

    return [IntelliJInfo(outputs = outputs), OutputGroupInfo(**outputs)]

intellij_info_aspect = aspect(
    implementation = _aspect_impl,
    attr_aspects = ["*"],
    required_aspect_providers = [[it] for it in intellij_provider.ALL.values()],
    provides = [IntelliJInfo],
)
