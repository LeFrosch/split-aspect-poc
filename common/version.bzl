load("@bazel_skylib//lib:versions.bzl", "versions")
load("//config:config.bzl", "config")

# load the version written to the repository rule and parse it
_BAZEL_VERSION = versions.parse(config.bazel_version)

def _geq(major, minor = 0, patch = 0):
    return _BAZEL_VERSION >= (major, minor, patch)

def _le(major, minor = 0, patch = 0):
    return _BAZEL_VERSION < (major, minor, patch)

bazel_version = struct(
    VERSION = _BAZEL_VERSION,
    geq = _geq,
    le = _le,
)
