load("//testing/rules:defs.bzl", "test_config", "test_fixture", "test_matrix")

test_config(
    name = "base",
    aspects = [
        "@intellij_aspect//modules:cc_info.bzl%intellij_cc_info_aspect",
        "@intellij_aspect//intellij:aspect.bzl%intellij_info_aspect",
    ],
    bazel = "@registry_bazel//:latest",
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
    ],
)

test_fixture(
    name = "simple",
    srcs = glob(["simple/**"]),
    configs = [":matrix"],
    strip_prefix = "simple",
    visibility = ["//testing/tests:__subpackages__"],
)

test_fixture(
    name = "transition",
    srcs = glob(["transition/**"]),
    configs = [":matrix"],
    strip_prefix = "transition",
    visibility = ["//testing/tests:__subpackages__"],
)
