load("@rules_cc//cc:defs.bzl", "CcToolchainConfigInfo", "cc_common")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_TYPE")
load("//common:common.bzl", "intellij_common")
load(":provider.bzl", "intellij_provider")

def _find_provider(ctx):
    """Tries to find the previously populated XCodeInfo provider either in the rule's attributes 
    or toolchains."""

    # check if there is any single target attribute that ha s the XCodeInfo provider
    for name in dir(ctx.rule.attr):
        target = intellij_common.attr_as_target(ctx, name)
        if not target:
            continue

        provider = intellij_provider.get(target, intellij_provider.XCodeInfo)
        if not provider:
            continue

        return provider

    # if there is no attribute check for the cc toolchain
    toolchains = getattr(ctx.rule, "toolchains", None)
    if not toolchains or CC_TOOLCHAIN_TYPE not in toolchains:
        return None

    return intellij_provider.get(toolchains[CC_TOOLCHAIN_TYPE], intellij_provider.XCodeInfo)

def _create_provider(target):
    """Populates the provider with the data from the xcode properties."""
    properties = target[apple_common.XcodeProperties]

    return intellij_provider.XCodeInfo(
        present = True,
        outputs = {},
        dependencies = {},
        value = intellij_common.struct(
            xcode_version = properties.xcode_version,
            default_macos_sdk_version = properties.default_macos_sdk_version,
        ),
    )

def _aspect_impl(target, ctx):
    """The aspects collects the data from the XcodeProperties provider and propagets the data up to 
    the top most toolchain target. This is required to access the data from the main provider.

    Assumes that the target the defines the XcodeProperties is a direct dependency of the tooolchain
    configuration.
    """

    # check if the target has the XcodeProperties provider
    if apple_common.XcodeProperties in target:
        return [_create_provider(target)]

    # forward the created provider along all toolchain targets
    if cc_common.CcToolchainInfo in target or CcToolchainConfigInfo in target:
        provider = _find_provider(ctx)
        if provider:
            return [provider]

    return [intellij_provider.XCodeInfo(present = False)]

intellij_xcode_info_aspect = intellij_common.aspect(
    implementation = _aspect_impl,
    provides = [intellij_provider.XCodeInfo],
    toolchains_aspects = [str(CC_TOOLCHAIN_TYPE)],
)
