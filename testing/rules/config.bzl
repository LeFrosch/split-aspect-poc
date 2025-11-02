load("//private:bazel_rules.bzl", "BazelBinary", "BazelModule")

TestConfig = provider(
    doc = "Single fixture configuration (Bazel, modules, aspects).",
    fields = {
        "bazel": "BazelBinary - Bazel binary used to build the fixture.",
        "modules": "list[BazelModule] - Modules the fixture depends upon.",
        "aspects": "list[str] - Aspects enabled when building the fixture.",
    },
)
TestMatrix = provider(
    doc = "Collection of derived test configurations.",
    fields = {
        "configs": "list[TestConfig] - Materialized configurations to execute.",
    },
)


def _test_config_impl(ctx):
    modules = [mod[BazelModule] for mod in ctx.attr.modules]

    # check for duplicate modules
    seen = {}
    for mod in modules:
        if mod.name in seen:
            fail("duplicate module definition: %s (%s)" % (mod.name, mod.version))
        seen[mod.name] = True

    return [
        TestConfig(
            bazel = ctx.attr.bazel[BazelBinary],
            modules = modules,
            aspects = ctx.attr.aspects,
        ),
        DefaultInfo(files = depset(ctx.files.bazel + ctx.files.modules)),
    ]

# A single configuration that describes how a test fixture should be processed.
test_config = rule(
    implementation = _test_config_impl,
    attrs = {
        "bazel": attr.label(
            mandatory = True,
            providers = [BazelBinary],
            doc = "bazel binary used to build the fixture",
        ),
        "modules": attr.label_list(
            mandatory = True,
            providers = [BazelModule],
            doc = "list of modules the fixture depends upon",
        ),
        "aspects": attr.string_list(
            mandatory = True,
            doc = "list of enabled aspects when building the fixture",
        ),
    },
    provides = [TestConfig],
)

def _test_matrix_impl(ctx):
    base_config = ctx.attr.base[TestConfig]

    bazel_binaries = [it[BazelBinary] for it in ctx.attr.bazel] or [base_config.bazel]
    modules = [it[BazelModule] for it in ctx.attr.modules]

    configs = [
        TestConfig(bazel = bazel, modules = base_config.modules + [mod], aspects = base_config.aspects)
        for bazel in bazel_binaries
        for mod in modules
    ]

    files = depset(transitive = [
        depset([it.executable for it in bazel_binaries]),
        depset([it.archive for it in modules + base_config.modules]),
    ])

    return [TestMatrix(configs = configs), DefaultInfo(files = files)]

# Takes a base configuration and derives multiple new configurations by adding a
# new module to the configuration or overwriting the bazel binary.
test_matrix = rule(
    implementation = _test_matrix_impl,
    attrs = {
        "modules": attr.label_list(
            mandatory = True,
            providers = [BazelModule],
        ),
        "bazel": attr.label_list(
            providers = [BazelBinary],
        ),
        "base": attr.label(
            mandatory = True,
            providers = [TestConfig],
        ),
    },
    provides = [TestMatrix],
)
