load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")

package(default_visibility = ["//testing:__subpackages__"])

kt_jvm_library(
    name = "utils",
    srcs = ["utils.kt"],
    deps = [
        "//testing/rules:aspect_fixture_java_proto",
        "@maven//:junit_junit",
        "@protobuf//:protobuf_java",
        "@rules_java//java/runfiles",
    ],
)

kt_jvm_library(
    name = "resource",
    srcs = ["resource.kt"],
    deps = [
        ":utils",
        "//testing/rules:aspect_fixture_java_proto",
        "@maven//:junit_junit",
        "@protobuf//:protobuf_java",
        "@rules_java//java/runfiles",
    ],
)
