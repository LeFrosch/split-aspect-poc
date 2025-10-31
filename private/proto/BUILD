load("@protobuf//bazel:java_proto_library.bzl", "java_proto_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")

proto_library(
    name = "common_proto",
    srcs = ["common.proto"],
    visibility = ["//visibility:private"],
)

java_proto_library(
    name = "common_java_proto",
    visibility = ["//visibility:private"],
    deps = [":common_proto"],
)


proto_library(
    name = "ide_info_proto",
    srcs = ["ide_info.proto"],
    visibility = ["//visibility:private"],
    deps = [":common_proto"],
)

java_proto_library(
    name = "ide_info_java_proto",
    visibility = ["//visibility:private"],
    deps = [":ide_info_proto"],
)
