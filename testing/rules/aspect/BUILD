load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")

kt_jvm_library(
    name = "builder_lib",
    srcs = ["builder.kt"],
    deps = [
        "//testing/rules:aspect_fixture_java_proto",
        "@protobuf//:protobuf_java",
    ],
)

java_binary(
    name = "builder_bin",
    main_class = "com.intellij.aspect.testing.rules.aspect.BuilderKt",
    runtime_deps = [":builder_lib"],
)
