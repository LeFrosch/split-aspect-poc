_BUILD_FILE_HEADER = """
load("@@//private:bazel_rules.bzl", "bazel_module", "bazel_binary")

package(default_visibility = ["//visibility:public"])
"""

_BUILD_FILE_MODULE = """
bazel_module(
    name = "{name}",
    module_name = "{module_name}",
    version = "{version}",
    archive = "{archive}",
)
"""

_BUILD_FILE_BINARY = """
bazel_binary(
    name = "{name}",
    version = "{version}",
    executable = "{executable}",
)
"""

_BUILD_FILE_LATEST_ALIAS = """
alias(
    name = "latest",
    actual = "{latest}",
)
"""

_BAZEL_URL_TEMPLATE = "https://github.com/bazelbuild/bazel/releases/download/{0}/bazel-{0}-{1}-{2}"

def _format_name(version):
    return version.replace(".", "_")

def _bazel_registry_impl(rctx):
    content = _BUILD_FILE_HEADER

    for version in rctx.attr.versions:
        name = _format_name(version)
        archive = "%s.tar.gz" % name

        rctx.download(
            rctx.attr.url_template.format(version),
            output = archive,
        )

        content += _BUILD_FILE_MODULE.format(
            name = name,
            module_name = rctx.attr.module_name,
            version = version,
            archive = archive,
        )

    content += _BUILD_FILE_LATEST_ALIAS.format(
        latest = _format_name(rctx.attr.versions[-1]),
    )

    rctx.file("BUILD", content)

# A repository that stores multiple versions of a single rule set.
bazel_registry = repository_rule(
    implementation = _bazel_registry_impl,
    attrs = {
        "module_name": attr.string(mandatory = True),
        "url_template": attr.string(mandatory = True),
        "versions": attr.string_list(mandatory = True),
    },
)

def _os_name(rctx):
    name = rctx.os.name.lower()

    if name.startswith("linux"):
        return "linux"
    if name.startswith("mac os"):
        return "darwin"
    if name.startswith("windows"):
        return "windows"

    fail("unrecognized os: %s" % name)

def _arch_name(rctx):
    arch = rctx.os.arch.lower()

    if arch.startswith("amd64") or arch.startswith("x86_64"):
        return "x86_64"
    if arch.startswith("aarch64") or arch.startswith("arm"):
        return "arm64"

    fail("unrecognized arch: %s" % arch)

def _bazel_repo_impl(rctx):
    content = _BUILD_FILE_HEADER

    for version in rctx.attr.versions:
        name = _format_name(version)
        executable = "%s_bin" % name

        rctx.download(
            _BAZEL_URL_TEMPLATE.format(version, _os_name(rctx), _arch_name(rctx)),
            output = executable,
            executable = True,
        )

        content += _BUILD_FILE_BINARY.format(
            name = name,
            version = version,
            executable = executable,
        )

    content += _BUILD_FILE_LATEST_ALIAS.format(
        latest = _format_name(rctx.attr.versions[-1]),
    )

    rctx.file("BUILD", content)

# A repository to store multiple bazel versions that can be executed on the
# local host.
bazel_binaries = repository_rule(
    implementation = _bazel_repo_impl,
    attrs = {"versions": attr.string_list(mandatory = True)},
)
