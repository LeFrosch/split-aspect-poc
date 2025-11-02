load("@protobuf//bazel:java_proto_library.bzl", "java_proto_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load("@rules_pkg//pkg:pkg.bzl", "pkg_zip")
load(":defs.bzl", "aspect_fixture", "aspect_project")

proto_library(
    name = "builder_proto",
    srcs = ["builder.proto"],
    deps = ["//private/proto:ide_info_proto"],
)

java_proto_library(
    name = "builder_java_proto",
    deps = [":builder_proto"],
)

kt_jvm_library(
    name = "builder_lib",
    srcs = ["builder.kt"],
    deps = [
        ":builder_java_proto",
        "@maven//:com_fasterxml_jackson_core_jackson_databind",
        "@protobuf//:protobuf_java",
    ],
)

java_binary(
    name = "builder_bin",
    main_class = "com.intellij.aspect.testing.rules.integration.BuilderKt",
    runtime_deps = [":builder_lib"],
)

aspect_project(
    name = "project",
    srcs = [
        "test/BUILD.fix",
        "test/simple.cc",
    ],
)

pkg_zip(
    name = "project_zip",
    srcs = [":project"],
)

aspect_fixture(
    name = "fixture",
    project = ":project_zip",
)
