load("@protobuf//bazel:java_proto_library.bzl", "java_proto_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")

package(default_visibility = ["//testing:__subpackages__"])

proto_library(
    name = "aspect_fixture_proto",
    srcs = ["aspect_fixture.proto"],
    deps = ["//private/proto:ide_info_proto"],
)

java_proto_library(
    name = "aspect_fixture_java_proto",
    deps = [":aspect_fixture_proto"],
)

kt_jvm_library(
    name = "builder_lib",
    srcs = ["builder.kt"],
    deps = [
        ":aspect_fixture_java_proto",
        "@protobuf//:protobuf_java",
    ],
)

java_binary(
    name = "builder_bin",
    main_class = "com.intellij.aspect.testing.rules.BuilderKt",
    runtime_deps = [":builder_lib"],
)
