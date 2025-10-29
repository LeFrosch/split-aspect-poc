load("@rules_cc//cc:defs.bzl", "CcInfo")
load("//common:artifact_location.bzl", "artifact_location")
load("//common:make_variables.bzl", "expand_make_variables")
load("//common:provider.bzl", "intellij_provider")

def _collect_rule_context(ctx):
    """Collect additional information from the rule attributes of cc_xxx rules."""

    if not ctx.rule.kind.startswith("cc_"):
        return struct()

    return struct(
        sources = artifact_location.from_attr(ctx, "srcs"),
        headers = artifact_location.from_attr(ctx, "hdrs"),
        textual_headers = artifact_location.from_attr(ctx, "textual_hdrs"),
        copts = expand_make_variables(ctx, True, getattr(ctx.rule.attr, "copts", [])),
        args = expand_make_variables(ctx, True, getattr(ctx.rule.attr, "args", [])),
        include_prefix = getattr(ctx.rule.attr, "include_prefix", ""),
        strip_include_prefix = getattr(ctx.rule.attr, "strip_include_prefix", ""),
    )

def _collect_compilation_context(ctx, target):
    """Collect information from the compilation context provided by the CcInfo provider."""

    compilation_context = target[CcInfo].compilation_context

    # merge current compilation context with context of implementation dependencies
    if ctx.rule.kind.startswith("cc_") and hasattr(ctx.rule.attr, "implementation_deps"):
        impl_deps = ctx.rule.attr.implementation_deps

        compilation_context = cc_common.merge_compilation_contexts(
            compilation_contexts = [compilation_context] + [it[CcInfo].compilation_context for it in impl_deps],
        )

    # external_includes available since bazel 7
    external_includes = getattr(compilation_context, "external_includes", depset()).to_list()

    return struct(
        headers = [artifact_location.from_file(it) for it in compilation_context.headers.to_list()],
        defines = compilation_context.defines.to_list(),
        includes = compilation_context.includes.to_list(),
        quote_includes = compilation_context.quote_includes.to_list(),
        # both system and external includes are added using `-isystem`
        system_includes = compilation_context.system_includes.to_list() + external_includes,
    )

def _aspect_guard(target, ctx):
    if CcInfo not in target:
        return False

    # ignore cc_proto_library, attach to proto_library with aspect attached instead
    if ctx.rule.kind == "cc_proto_library":
        return False

    # Go targets always provide CcInfo. Usually it's empty, but even if it isn't we don't handle it
    if ctx.rule.kind.startswith("go_"):
        return False

    return True

def _aspect_impl(target, ctx):
    if not _aspect_guard(target, ctx):
        return [intellij_provider.CcInfo(present = False)]

    # TODO(brendandouglas): target to cpp files only
    compile_files = target[OutputGroupInfo].compilation_outputs if hasattr(target[OutputGroupInfo], "compilation_outputs") else depset([])
    resolve_files = target[CcInfo].compilation_context.headers

    return [intellij_provider.CcInfo(
        present = True,
        outputs = {
            "intellij-compile-cpp": compile_files,
            "intellij-resolve-cpp": resolve_files,
        },
        value = struct(
            rule_context = _collect_rule_context(ctx),
            compilation_context = _collect_compilation_context(ctx, target),
        ),
    )]

intellij_cc_info_aspect = aspect(
    implementation = _aspect_impl,
    attr_aspects = ["*"],
    fragments = ["cpp"],
    provides = [intellij_provider.CcInfo],
)

