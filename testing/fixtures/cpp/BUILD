load("//testing/rules:defs.bzl", "test_config", "test_fixture", "test_matrix")

test_config(
    name = "base",
    aspects = [
        "@intellij_aspect//modules:xcode_info.bzl%intellij_xcode_info_aspect",
        "@intellij_aspect//modules:cc_info.bzl%intellij_cc_info_aspect",
        "@intellij_aspect//intellij:aspect.bzl%intellij_info_aspect",
    ],
    bazel = "@registry_bazel//:8_4_2",
    modules = ["//testing/rules:aspect_module"],
)

test_matrix(
    name = "matrix",
    base = ":base",
    bazel = [
        "@registry_bazel//:7_7_0",
        "@registry_bazel//:8_4_2",
    ],
    modules = [
        "@registry_rules_cc//:0_1_1",
        "@registry_rules_cc//:0_2_9",
        "@registry_rules_cc//:0_2_14",
    ],
)

test_config(
    name = "bazel9",
    aspects = [
        "@intellij_aspect//modules:xcode_info.bzl%intellij_xcode_info_aspect",
        "@intellij_aspect//modules:cc_info.bzl%intellij_cc_info_aspect",
        "@intellij_aspect//intellij:aspect.bzl%intellij_info_aspect",
    ],
    bazel = "@registry_bazel//:9_0_0rc5",
    modules = [
        "//testing/rules:aspect_module",
        "@registry_rules_cc//:0_2_14",
    ],
)

test_fixture(
    name = "simple",
    srcs = glob(["simple/**"]),
    configs = [
        ":bazel9",
        ":matrix",
    ],
    strip_prefix = "simple",
    visibility = ["//testing/tests:__subpackages__"],
)

test_fixture(
    name = "transition",
    srcs = glob(["transition/**"]),
    configs = [":bazel9"],
    strip_prefix = "transition",
    visibility = ["//testing/tests:__subpackages__"],
)

test_fixture(
    name = "builtin",
    srcs = glob(["builtin/**"]),
    configs = [":matrix"],
    strip_prefix = "builtin",
    visibility = ["//testing/tests:__subpackages__"],
)

test_fixture(
    name = "tool",
    srcs = glob(["tool/**"]),
    configs = [":bazel9"],
    strip_prefix = "tool",
    visibility = ["//testing/tests:__subpackages__"],
)
