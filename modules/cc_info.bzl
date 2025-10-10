load("@rules_cc//cc:defs.bzl", "CcInfo")
load(":common.bzl", "intellij_common")

def _aspect_impl(target, ctx):
    if not CcInfo in target:
        return [intellij_common.IntelliJCcInfo(present = False)]

    return [intellij_common.IntelliJCcInfo(
        present = True,
        outputs = {},
        value = "CcInfo found on target",
    )]

intellij_cc_info_aspect = aspect(
    implementation = _aspect_impl,
    attr_aspects = ["*"],
    fragments = ["cpp"],
    provides = [intellij_common.IntelliJCcInfo],
)
