load("@rules_java//java:defs.bzl", "java_binary", "java_library")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")

java_library(
    name = "runfiles_repo",
    srcs = ["RunfilesRepo.java"],
    visibility = ["//visibility:private"],
    deps = ["@rules_java//java/runfiles"],
)

kt_jvm_library(
    name = "differ_lib",
    srcs = glob(["differ/*.kt"]),
    visibility = ["//visibility:private"],
    deps = [
        ":runfiles_repo",
        "//private/lib:deploy",
        "//private/lib:exec",
        "//private/proto:common_java_proto",
        "//private/proto:ide_info_java_proto",
        "@maven//:com_fasterxml_jackson_core_jackson_databind",
        "@maven//:org_jetbrains_kotlinx_kotlinx_cli_jvm",
        "@protobuf//:protobuf_java",
    ],
)

java_binary(
    name = "differ",
    data = [
        ":legacy_aspect.zip",
        "//:archive_ide",
    ],
    main_class = "com.intellij.aspect.tools.differ.MainKt",
    runtime_deps = [":differ_lib"],
)
