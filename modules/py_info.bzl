load("@rules_python//python:defs.bzl", "PyInfo")
load(":common.bzl", "intellij_common")

def _aspect_impl(target, ctx):
    if not PyInfo in target:
        return []

    return [intellij_common.IntelliJPyInfo(
        outputs = {},
        value = "PyInfo found on target",
    )]

intellij_py_info_aspect = aspect(
    implementation = _aspect_impl,
    attr_aspects = ["*"],
    required_providers = [PyInfo],
    required_aspect_providers = [PyInfo],
    fragments = ["py"],
    provides = [intellij_common.IntelliJPyInfo],
)
