load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_java//java:defs.bzl", "java_test")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load("@rules_pkg//pkg:pkg.bzl", "pkg_zip")
load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")

def _aspect_project_impl(ctx):
    package = ctx.label.package

    map = {
        paths.relativize(file.short_path.removesuffix(".fix"), package): file
        for file in ctx.files.srcs
    }

    return [
        DefaultInfo(files = depset(map.values())),
        PackageFilesInfo(dest_src_map = map),
    ]

_aspect_project = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
    },
    implementation = _aspect_project_impl,
)

def _aspect_fixture_build(ctx, config):
    output_file = ctx.actions.declare_file(ctx.label.name + ".intellij-aspect-fixture")

    args = struct(
        bazel_executable = config.bazel.path,
        project_zip = ctx.file.project.path,
        output_file = output_file.path,
        overrides = [
            struct(name = "intellij_aspect", archive = ctx.file._aspect.path),
            struct(name = "rules_cc", archive = config.rules_cc.path),
            struct(name = "rules_python", archive = config.rules_python.path),
        ],
    )


def _aspect_fixture_impl(ctx):
    output_file = ctx.actions.declare_file(ctx.label.name + ".intellij-aspect-fixture")

    args = struct(
        bazel_executable = ctx.file.bazel.path,
        project_zip = ctx.file.project.path,
        output_file = output_file.path,
        overrides = [
            struct(name = "intellij_aspect", archive = ctx.file._aspect.path),
            struct(name = "rules_cc", archive = ctx.file.rules_cc.path),
            struct(name = "rules_python", archive = ctx.file.rules_python.path),
        ],
    )

    ctx.actions.run(
        inputs = [
            ctx.file.bazel,
            ctx.file.project,
            ctx.file._aspect,
            ctx.file.rules_cc,
            ctx.file.rules_python,
        ],
        outputs = [output_file],
        executable = ctx.executable._builder,
        arguments = [proto.encode_text(args)],
        mnemonic = "FixtureBuilder",
        progress_message = "Building Aspect Fixutre",
        use_default_shell_env = True,
    )

    return [DefaultInfo(files = depset([output_file]))]

_aspect_fixture = rule(
    attrs = {
        "project": attr.label(
            allow_single_file = [".zip"],
            mandatory = True,
        ),
        "bazel": attr.label_list(
            allow_files = True,
            default = [Label("@integration_test_bazel//:latest")],
        ),
        "rules_cc": attr.label_list(
            allow_files = [".tar.gz"],
            default = [Label("@integration_test_rules_cc//:latest")],
        ),
        "rules_python": attr.label_list(
            allow_files = [".tar.gz"],
            default = [Label("@integration_test_rules_python//:latest")],
        ),
        "_aspect": attr.label(
            allow_single_file = [".zip"],
            default = Label("//:archive_bcr"),
        ),
        "_builder": attr.label(
            allow_files = True,
            cfg = "exec",
            executable = True,
            default = Label("//testing/rules/integration:builder_bin"),
        ),
    },
    implementation = _aspect_fixture_impl,
)

def aspect_fixture(name, test, srcs, bazel = None):
    """
    Creates an aspect test.

    The fixture can be loaded in the test using
    the IntellijAspectResource:

    @Rule
    @JvmField
    val aspect: IntellijAspectResource = IntellijAspectResource()
    """

    _aspect_project(
        name = name + "_project",
        srcs = srcs,
        testonly = 1,
    )

    pkg_zip(
        name = name + "_zip",
        srcs = [":project"],
        testonly = 1,
    )

    _aspect_fixture(
        name = name + "_fixture",
        project = name + "_project",
        testonly = 1,
    )
