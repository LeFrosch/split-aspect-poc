def _intellij_info_provider():
    return provider(
        doc = "Module-specific IntelliJ metadata for a single target.",
        fields = {
            "outputs": "dict[str, depset[File]] - Output groups produced by this module.",
            "dependencies": "dict[int, depset[Target]] - Direct dependencies grouped by dependency type.",
            "value": "struct - Module-specific value serializable to protobuf.",
            "present": "bool - Whether the provider is present on this target.",
        },
    )

_IntelliJCcInfo = _intellij_info_provider()
_IntelliJCcToolchainInfo = _intellij_info_provider()
_IntelliJXCodeInfo = _intellij_info_provider()
_IntelliJPyInfo = _intellij_info_provider()

_PROVIDERS = {
    "c_ide_info": _IntelliJCcInfo,
    "c_toolchain_ide_info": _IntelliJCcToolchainInfo,
    "xcode_ide_info": _IntelliJXCodeInfo,
    "py_ide_info": _IntelliJPyInfo,
}

def _has_any_provider(target):
    for provider in _PROVIDERS.values():
        if provider in target and target[provider].present:
            return True

    return False

def _get_provider_or_none(target, provider):
    if not provider in target:
        return None

    instance = target[provider]
    if not instance.present:
        return None

    return instance

intellij_provider = struct(
    CcInfo = _IntelliJCcInfo,
    CcToolchainInfo = _IntelliJCcToolchainInfo,
    XCodeInfo = _IntelliJXCodeInfo,
    PyInfo = _IntelliJPyInfo,
    ALL = _PROVIDERS,
    any = _has_any_provider,
    get = _get_provider_or_none,
)
