def _intellij_info_provider():
    return provider(
        doc = "Module-specific information for a single target.",
        fields = {
            "outputs": "A `dict` mapping an output group name to a `depset` of output files.",
            "dependencies": "A `dict` mapping a dependency group name to a `list` of direct dependencies.",
            "value": "Module-specific value. The value has to be a `struct` that can be serialized to protobuf.",
            "present": "A `bool` indicating whether the provider is present.",
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
