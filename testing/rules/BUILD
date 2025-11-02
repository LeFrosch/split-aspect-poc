load("@protobuf//bazel:java_proto_library.bzl", "java_proto_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")

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
