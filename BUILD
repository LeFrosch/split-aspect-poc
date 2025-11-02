load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_pkg//pkg:pkg.bzl", "pkg_tar", "pkg_zip")

copy_file(
    name = "module_bcr",
    src = "MODULE.bazel.bcr",
    out = "MODULE.bazel",
)

pkg_zip(
    name = "archive_ide",
    srcs = [
        "//common",
        "//intellij",
        "//modules",
    ],
    visibility = ["//visibility:public"],
)

pkg_tar(
    name = "archive_bcr",
    srcs = [
        ":module_bcr",
        "//common",
        "//config",
        "//intellij",
        "//modules",
    ],
    extension = "tar.gz",
    package_dir = "intellij_aspect",
    visibility = ["//visibility:public"],
)
