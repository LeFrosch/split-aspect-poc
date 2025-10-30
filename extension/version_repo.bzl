load("@bazel_skylib//lib:versions.bzl", "versions")

# source: https://github.com/bazel-contrib/bazel_features/blob/main/private/version_repo.bzl
def _version_repo_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        """
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(["version.bzl"])

bzl_library(
    name = "version",
    srcs = ["version.bzl"],
    visibility = ["//visibility:public"],
)
""",
    )
    rctx.file("version.bzl", "version = '" + versions.get() + "'")

version_repo = repository_rule(
    _version_repo_impl,
    local = True,  # force reruns on server restarts to keep native.bazel_version up-to-date.
)
