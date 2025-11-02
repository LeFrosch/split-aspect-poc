load("@rules_python//python:defs.bzl", "py_test")
load("//testing/rules:aspect_test.bzl", "aspect_test")

py_test(
    name = "simple",
    srcs = ["simple.py"],
    python_version = "PY3",
    srcs_version = "PY3",
)

aspect_test(
    name = "PyTestTest",
    data = [":simple"],
    test = "PyTestTest.kt",
)
