load(":repos.bzl", "bazel_repo", "rule_repo")

_install = tag_class(attrs = {
    "bazel": attr.string_list(),
    "rules_cc": attr.string_list(),
    "rules_python": attr.string_list(),
})

def _collect_versions(mctx, attr_name):
    return [
        version
        for mod in mctx.modules
        for tag in mod.tags.install
        for version in getattr(tag, attr_name)
    ]

def _integration_test_extension_impl(mctx):
    bazel_repo(
        name = "integration_test_bazel",
        versions = _collect_versions(mctx, "bazel"),
    )
    rule_repo(
        name = "integration_test_rules_cc",
        url_template = "https://github.com/bazelbuild/rules_cc/releases/download/{0}/rules_cc-{0}.tar.gz",
        versions = _collect_versions(mctx, "rules_cc"),
    )
    rule_repo(
        name = "integration_test_rules_python",
        url_template = "https://github.com/bazel-contrib/rules_python/releases/download/{0}/rules_python-{0}.tar.gz",
        versions = _collect_versions(mctx, "rules_python"),
    )

integration_test = module_extension(
    implementation = _integration_test_extension_impl,
    tag_classes = {"install": _install},
)
