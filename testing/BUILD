load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_python//python:py_binary.bzl", "py_binary")
load(":multi_arch_binary.bzl", "multi_arch_binary")

cc_binary(
    name = "cc_main",
    srcs = [":main.cc"],
)

multi_arch_binary(
    name = "cc_multi_arch",
    dep = ":cc_main",
)

py_binary(
    name = "py_main",
    srcs = [":main.py"],
    main = ":main.py",
)
