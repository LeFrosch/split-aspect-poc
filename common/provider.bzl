def _intellij_info_provider():
    return provider(fields = ["outputs", "value", "present"])

_IntelliJCcInfo = _intellij_info_provider()
_IntelliJPyInfo = _intellij_info_provider()

_PROVIDERS = {
    "cc_info": _IntelliJCcInfo,
    "py_info": _IntelliJPyInfo,
}

def _has_any_provider(target):
    for provider in _PROVIDERS.values():
        if provider in target and target[provider].present:
            return True

    return False

intellij_provider = struct(
    CcInfo = _IntelliJCcInfo,
    PyInfo = _IntelliJPyInfo,
    ALL = _PROVIDERS,
    any = _has_any_provider,
)
