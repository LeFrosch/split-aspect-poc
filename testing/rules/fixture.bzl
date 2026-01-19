load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load(":config.bzl", "TestConfig", "TestMatrix")

def _test_project_impl(ctx):
    package = "%s/%s" % (ctx.label.package, ctx.attr.strip_prefix)

    map = {
        paths.relativize(file.short_path.removesuffix(".fix"), package): file
        for file in ctx.files.srcs
    }

    return [
        DefaultInfo(files = depset(map.values())),
        PackageFilesInfo(dest_src_map = map),
    ]

_test_project = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "strip_prefix": attr.string(default = ""),
    },
    implementation = _test_project_impl,
)

def _config_name(config):
    """
    A user friendly name for the configuration, including bazel and module
    versions.
    """
    parts = ["bazel:%s" % config.bazel.version] + [
        "%s:%s" % (mod.name, mod.version)
        for mod in config.modules
    ]

    return "[%s]" % ", ".join(parts)

def _config_hash(config):
    """
    Generates a unique hash for the configuration. Used to generate unique file
    names for every fixture.
    """
    parts = [config.bazel.version]
    parts.extend([mod.name for mod in config.modules])
    parts.extend([mod.version for mod in config.modules])
    parts.extend(config.aspects)

    return hash(".".join(parts))

def _config_encode(config, project, targets, output):
    """
    Encodes the fixture for passing it to the builder. Has to follow the schema
    defined in builder.proto.
    """
    return proto.encode_text(struct(
        project_tar = project.path,
        output_file = output.path,
        bazel = struct(
            version = config.bazel.version,
            executable = config.bazel.executable.path,
        ),
        modules = [
            struct(name = mod.name, version = mod.version, archive = mod.archive.path)
            for mod in config.modules
        ],
        aspects = config.aspects,
        targets = targets,
    ))

def _test_fixture_impl(ctx):
    outputs = []

    configs = []
    for dep in ctx.attr.configs:
        if TestConfig in dep:
            configs.append(dep[TestConfig])
        if TestMatrix in dep:
            configs.extend(dep[TestMatrix].configs)

    for config in configs:
        output = ctx.actions.declare_file("%s-%s.intellij-aspect-fixture" % (ctx.label.name, _config_hash(config)))

        ctx.actions.run(
            inputs = [
                ctx.file.project,
                config.bazel.executable,
            ] + [
                mod.archive
                for mod in config.modules
            ],
            outputs = [output],
            executable = ctx.executable._builder,
            arguments = [_config_encode(config, ctx.file.project, ctx.attr.targets, output)],
            mnemonic = "FixtureBuilder",
            progress_message = "Building test fixture for %{label} " + _config_name(config),
            use_default_shell_env = True,
        )

        outputs.append(output)

    return [DefaultInfo(files = depset(outputs))]

_test_fixture = rule(
    attrs = {
        "project": attr.label(
            allow_single_file = [".tar.gz"],
            mandatory = True,
        ),
        "configs": attr.label_list(
            providers = [[TestConfig], [TestMatrix]],
            mandatory = True,
        ),
        "targets": attr.string_list(
            mandatory = True,
            doc = "list of targets to build for the fixture; do not us patterns",
        ),
        "_builder": attr.label(
            allow_files = True,
            cfg = "exec",
            executable = True,
            default = Label("//testing/rules:builder_bin"),
        ),
    },
    implementation = _test_fixture_impl,
)

def test_fixture(name, srcs, configs, targets, strip_prefix = "", **kwargs):
    """
    Creates a test fixture by running the aspect on the source project for all
    defined configurations. The fixture can be passed to a test runner which
    executes all test for every generated fixture.
    """
    _test_project(
        name = name + "_project",
        srcs = srcs,
        visibility = ["//visibility:private"],
        strip_prefix = strip_prefix,
        testonly = 1,
    )

    pkg_tar(
        name = name + "_tar",
        srcs = [name + "_project"],
        extension = "tar.gz",
        package_dir = "project",
        visibility = ["//visibility:private"],
        testonly = 1,
    )

    _test_fixture(
        name = name,
        project = name + "_tar",
        configs = configs,
        testonly = 1,
        targets = targets,
        **kwargs
    )
