load("//testing/rules:defs.bzl", "junit_test")

junit_test(
    data = ["//:archive_ide"],
    env = {
        "ARCHIVE_IDE": "$(rlocationpaths //:archive_ide)",
    },
    test = "DeployTest.kt",
    deps = [
        "//private/lib:deploy",
        "@rules_java//java/runfiles",
    ],
)
