load("@rules_java//java:defs.bzl", "java_test")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load("//testing/rules/cache:cache.bzl", _repo_cache = "repo_cache")
load("//testing/rules/fixture:fixture.bzl", _test_fixture = "test_fixture")
load("//testing/rules/lib:config.bzl", _test_matrix = "test_matrix")
load("//testing/rules/lib:project.bzl", _project_archive = "project_archive")

test_matrix = _test_matrix

def test_fixture(name, srcs, config, strip_prefix = "", export_cache = None, import_cache = None, **kwargs):
    _project_archive(
        name = name + "_project",
        srcs = srcs,
        visibility = ["//visibility:private"],
        strip_prefix = strip_prefix or name,
        testonly = 1,
    )

    if export_cache:
        _repo_cache(
            name = export_cache,
            config = config,
            project = name + "_project",
            visibility = ["//visibility:private"],
            testonly = 1,
        )

    _test_fixture(
        name = name,
        config = config,
        project = name + "_project",
        repo_cache = export_cache or import_cache,
        testonly = 1,
        **kwargs
    )

def _derive_test_class(test):
    """
    Derives the full test_class path from the current package and naming
    convention. All tests need to follow the test package naming convention.
    """

    class_name = test.removesuffix(".kt")
    relative_path = native.package_name().replace("/", ".")

    return "com.intellij.aspect.%s.%s" % (relative_path, class_name)

def test_runner(test, fixture, deps = None, env = None):
    """
    Creates a test runner. Runs the test for iterations of the fixture. The
    fixture can be loaded and iterated in the test using the AspectFixture rule:

    @Rule
    @JvmField
    val aspect = AspectFixture()
    """
    name = test.removesuffix(".kt")

    kt_jvm_library(
        name = name + "_lib",
        srcs = [test],
        deps = (deps or []) + [
            "//testing/rules/fixture:fixture_lib",
            "//testing/rules/lib:test_utils_lib",
            "//private/proto:ide_info_java_proto",
            "@maven//:junit_junit",
            "@maven//:com_google_truth_truth",
        ],
        visibility = ["//visibility:private"],
        testonly = 1,
    )

    java_test(
        name = name,
        data = [fixture],
        runtime_deps = [name + "_lib"],
        test_class = _derive_test_class(test),
        env = (env or {}) | {
            "ASPECT_FIXTURES": "$(rlocationpaths %s)" % (fixture),
        },
    )

def junit_test(test, deps = None, **kwargs):
    """Creates a JUint4 test. All JUnit dependencies are provided."""
    name = test.removesuffix(".kt")

    kt_jvm_library(
        name = name + "_lib",
        srcs = [test],
        deps = (deps or []) + [
            "@maven//:junit_junit",
            "@maven//:com_google_truth_truth",
        ],
        visibility = ["//visibility:private"],
        testonly = 1,
    )

    java_test(
        name = name,
        runtime_deps = [name + "_lib"],
        test_class = _derive_test_class(test),
        **kwargs
    )
