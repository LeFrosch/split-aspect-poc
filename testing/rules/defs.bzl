load("@rules_java//java:defs.bzl", "java_test")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load(":config.bzl", _test_config = "test_config", _test_matrix = "test_matrix")
load(":fixture.bzl", _test_fixture = "test_fixture")

test_config = _test_config
test_matrix = _test_matrix

test_fixture = _test_fixture

def test_runner(name, test, fixture, deps = None, env = None):
    """
    Creates a test runner. Runs the test for iterations of the fixture. The
    fixture can be loaded and iterated in the test using the AspectFixture rule:

    @Rule
    @JvmField
    val aspect = AspectFixture()
    """
    kt_jvm_library(
        name = name + "_lib",
        srcs = [test],
        deps = (deps or []) + [
            "//testing/rules:fixture",
            "//testing/rules:utils",
            "//private/proto:ide_info_java_proto",
            "@maven//:junit_junit",
            "@maven//:com_google_truth_truth",
        ],
        testonly = 1,
    )

    java_test(
        name = name,
        data = [fixture],
        runtime_deps = [name + "_lib"],
        test_class = "com.intellij.aspect.%s.%s" % (native.package_name().replace("/", "."), test.removesuffix(".kt")),
        visibility = ["//testing:__subpackages__"],
        env = (env or {}) | {
            "ASPECT_FIXTURES": "$(rlocationpaths %s)" % (fixture),
        },
    )
