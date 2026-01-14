load("@rules_java//java:defs.bzl", "JavaInfo")
load("//common:artifact_location.bzl", "artifact_location")
load("//common:common.bzl", "intellij_common")
load(":provider.bzl", "intellij_provider")

def _aspect_impl(target, ctx):
    if not JavaInfo in target:
        return [intellij_provider.JavaInfo(present = False)]
    all_sources = artifact_location.from_attr(ctx, "srcs")
    return [intellij_provider.create(
        provider = intellij_provider.JavaInfo,
        value = intellij_common.struct(
            sources = [s for s in all_sources if s.is_source],
            generated_sources = [s for s in all_sources if not s.is_source],
        ),
    )]

intellij_java_info_aspect = intellij_common.aspect(
    implementation = _aspect_impl,
    provides = [intellij_provider.JavaInfo],
)
