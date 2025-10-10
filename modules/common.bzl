def _intellij_info_provider():
    return provider(fields = ["outputs", "value"])

_IntelliJCcInfo = _intellij_info_provider()
_IntelliJPyInfo = _intellij_info_provider()

_PROVIDERS = {
    "cc_info": _IntelliJCcInfo,
    "py_info": _IntelliJPyInfo,
}

def _has_provider(target):
    for provider in _PROVIDERS.values():
        if provider in target:
            return True

    return False

intellij_common = struct(
    IntelliJCcInfo = _IntelliJCcInfo,
    IntelliJPyInfo = _IntelliJPyInfo,
    PROVIDERS = _PROVIDERS,
    has_provider = _has_provider,
)
