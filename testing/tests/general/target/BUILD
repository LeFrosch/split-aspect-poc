load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("//testing/rules/aspect:defs.bzl", "aspect_test")

cc_binary(
    name = "simple",
    srcs = ["simple.cc"],
)

aspect_test(
    name = "BuildFileTest",
    data = [":simple"],
    test = "TargetTest.kt",
)
