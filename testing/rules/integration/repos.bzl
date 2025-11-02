_BUILD_FILE_TEMPLATE = """
package(default_visibility = ["//visibility:public"])

exports_files([{files}])

alias(
    name = "latest",
    actual = "{latest}",
)
"""

_BAZEL_URL_TEMPLATE = "https://github.com/bazelbuild/bazel/releases/download/{0}/bazel-{0}-{1}-{2}"

def _build_file(rctx, files):
    content = _BUILD_FILE_TEMPLATE.format(
        files = ",".join(["'%s'" % f for f in files]),
        latest = files[-1],
    )
    rctx.file("BUILD", content)

def _rule_repo_impl(rctx):
    for version in rctx.attr.versions:
        rctx.download(
            rctx.attr.url_template.format(version),
            output = "archive_%s.tar.gz" % version,
        )

    _build_file(rctx, files = ["archive_%s.tar.gz" % version for version in rctx.attr.versions])

rule_repo = repository_rule(
    implementation = _rule_repo_impl,
    attrs = {
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
    for version in rctx.attr.versions:
        rctx.download(
            _BAZEL_URL_TEMPLATE.format(version, _os_name(rctx), _arch_name(rctx)),
            output = "bazel_%s" % version,
            executable = True,
        )

    _build_file(rctx, files = ["bazel_%s" % version for version in rctx.attr.versions])

bazel_repo = repository_rule(
    implementation = _bazel_repo_impl,
    attrs = {"versions": attr.string_list(mandatory = True)},
)
