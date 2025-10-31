load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("//testing/rules:aspect_test.bzl", "aspect_test")
load(":multi_arch_binary.bzl", "multi_arch_binary")

cc_binary(
    name = "simple",
    srcs = [":simple.cc"],
)

multi_arch_binary(
    name = "multi_arch",
    dep = ":simple",
)

aspect_test(
    name = "TransitionTest",
    data = [":multi_arch"],
    test = "TransitionTest.kt",
)
