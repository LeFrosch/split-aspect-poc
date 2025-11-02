load("@rules_python//python:defs.bzl", "py_binary")
load("//testing/rules:aspect_test.bzl", "aspect_test")

py_binary(
    name = "simple",
    srcs = ["simple.py"],
    python_version = "PY3",
)

py_binary(
    name = "simple3",
    srcs = ["simple.py"],
    main = "simple.py",
    python_version = "PY3",
)

py_binary(
    name = "buildfile_args",
    srcs = ["simple.py"],
    args = [
        "--ARG1",
        "--ARG2=$(COMPILATION_MODE)",
        "--ARG3='with spaces'",
    ],
    main = "simple.py",
    python_version = "PY3",
)

py_binary(
    name = "expand_datadeps",
    srcs = ["simple.py"],
    args = [
        "--ARG1=$(location :datadepfile)",
    ],
    data = [":datadepfile"],
    main = "simple.py",
    python_version = "PY3",
)

genrule(
    name = "datadepfile",
    outs = ["datadepfile.txt"],
    cmd = "touch $@",
)

aspect_test(
    name = "PyBinaryTest",
    data = [
        ":buildfile_args",
        ":expand_datadeps",
        ":simple",
        ":simple3",
    ],
    env = {"COMPILATION_MODE_FOR_TEST": "$(COMPILATION_MODE)"},
    test = "PyBinaryTest.kt",
)
