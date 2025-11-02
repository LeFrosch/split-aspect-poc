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
_IntelliJPyInfo = _intellij_info_provider()

_PROVIDERS = {
    "c_ide_info": _IntelliJCcInfo,
    "c_toolchain_ide_info": _IntelliJCcToolchainInfo,
    "py_ide_info": _IntelliJPyInfo,
}

def _has_any_provider(target):
    for provider in _PROVIDERS.values():
        if provider in target and target[provider].present:
            return True

    return False

intellij_provider = struct(
    CcInfo = _IntelliJCcInfo,
    CcToolchainInfo = _IntelliJCcToolchainInfo,
    PyInfo = _IntelliJPyInfo,
    ALL = _PROVIDERS,
    any = _has_any_provider,
)
