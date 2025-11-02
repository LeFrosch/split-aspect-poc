load("@rules_python//python:defs.bzl", "py_library")
load("//testing/rules/aspect:defs.bzl", "aspect_test")

py_library(
    name = "simple",
    srcs = ["simple.py"],
    srcs_version = "PY3",
)

aspect_test(
    name = "PyLibraryTest",
    data = [":simple"],
    test = "PyLibraryTest.kt",
)
