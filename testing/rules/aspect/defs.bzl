load("@rules_java//java:defs.bzl", "java_test")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load("//intellij:aspect.bzl", "intellij_info_aspect")
load("//intellij:provider.bzl", "IntelliJInfo", "intellij_info")
load("//modules:cc_info.bzl", "intellij_cc_info_aspect")
load("//modules:py_info.bzl", "intellij_py_info_aspect")

def _aspect_fixture_impl(ctx):
    provider = intellij_info.create()
    for dep in ctx.attr.deps:
        intellij_info.update(provider, dep[IntelliJInfo])

    input_files = []
    for group, files in provider.outputs.items():
        input_file = ctx.actions.declare_file(group)
        input_files.append(input_file)

        ctx.actions.write(input_file, content = "\n".join([file.path for file in files.to_list()]))

    output_file = ctx.actions.declare_file(ctx.label.name + ".intellij-aspect-fixture")

    ctx.actions.run(
        inputs = intellij_info.get_ide_info(provider).to_list() + input_files,
        outputs = [output_file],
        executable = ctx.executable._builder,
        arguments = [output_file.path] + ["@" + file.path for file in input_files],
        mnemonic = "AspectFixtureBuilder",
        progress_message = "Building IntelliJ aspect test fixutre",
    )

    return [DefaultInfo(files = depset([output_file]))]

aspect_fixture = rule(
    attrs = {
        "deps": attr.label_list(
            aspects = [
                intellij_cc_info_aspect,
                intellij_py_info_aspect,
                intellij_info_aspect,
            ],
            providers = [IntelliJInfo],
        ),
        "_builder": attr.label(
            allow_files = True,
            cfg = "exec",
            default = Label("//testing/rules/aspect:builder_bin"),
            executable = True,
        ),
    },
    implementation = _aspect_fixture_impl,
)

def aspect_test(name, test, data, deps = None, env = None):
    """
    Creates an aspect test. Runs the aspect on `aspect_deps` and makes the
    result available as a fixture. The fixture can be loaded in the test using
    the IntellijAspectResource:

    @Rule
    @JvmField
    val aspect: IntellijAspectResource = IntellijAspectResource()
    """
    aspect_fixture(
        name = name + "_fixture",
        deps = data,
        testonly = 1,
    )

    kt_jvm_library(
        name = name + "_lib",
        srcs = [test],
        deps = (deps or []) + [
            "//testing/utils:resource",
            "//private/proto:ide_info_java_proto",
            "@maven//:junit_junit",
            "@maven//:com_google_truth_truth",
        ],
        testonly = 1,
    )

    java_test(
        name = name,
        data = [name + "_fixture"],
        runtime_deps = [name + "_lib"],
        test_class = "com.intellij.aspect.%s.%s" % (native.package_name().replace("/", "."), test.removesuffix(".kt")),
        visibility = ["//testing:__subpackages__"],
        env = (env or {}) | {
            "ASPECT_FIXTURE": "$(rlocationpath %s)" % (name + "_fixture"),
        },
    )
