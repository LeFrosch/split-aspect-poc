load("//testing/rules:project.bzl", "project_archive")
load("//testing/rules/cache:cache.bzl", "repo_cache")
load("//testing/rules/lib:config.bzl", "test_matrix")

package(
    default_testonly = 1,
    default_visibility = ["//testing/tests:__subpackages__"],
)

test_matrix(
    name = "matrix",
    aspects = [
        "@intellij_aspect//modules:xcode_info.bzl%intellij_xcode_info_aspect",
        "@intellij_aspect//modules:cc_info.bzl%intellij_cc_info_aspect",
        "@intellij_aspect//intellij:aspect.bzl%intellij_info_aspect",
    ],
    bazel = [
        "@registry_bazel//:7_7_0",
        "@registry_bazel//:8_5_1",
        "@registry_bazel//:9_0_0",
    ],
    modules = {
        "rules_cc": [
            "0.1.1",
            "0.2.9",
            "0.2.14",
        ],
    },
)

# test_fixture(
#     name = "simple",
#     srcs = glob(["simple/**"]),
#     configs = [
#         ":bazel9",
#         ":matrix",
#     ],
#     targets = ["//:main"],
# )
#
# test_fixture(
#     name = "transition",
#     srcs = glob(["transition/**"]),
#     configs = [":bazel9"],
#     targets = [
#         "//:main",
#         "//:foo_bar",
#     ],
# )
#
# test_fixture(
#     name = "builtin",
#     srcs = glob(["builtin/**"]),
#     configs = [":matrix"],
#     targets = ["//:main"],
# )
#
# test_fixture(
#     name = "tool",
#     srcs = glob(["tool/**"]),
#     configs = [":bazel9"],
#     targets = ["//:tool"],
# )

project_archive(
    name = "simple_archive",
    srcs = glob(["simple/**"]),
    strip_prefix = "simple",
)

repo_cache(
    name = "simple_cache",
    config = ":matrix",
    project = ":simple_archive",
)
