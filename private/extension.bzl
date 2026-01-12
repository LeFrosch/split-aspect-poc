load("//private:bazel_repos.bzl", "bazel_binaries", "bazel_registry")

_install = tag_class(attrs = {
    "bazel": attr.string_list(),
    "rules_cc": attr.string_list(),
    "rules_python": attr.string_list(),
    "rules_java": attr.string_list(),
})

def _collect_versions(mctx, attr_name):
    return [
        version
        for mod in mctx.modules
        for tag in mod.tags.install
        for version in getattr(tag, attr_name)
    ]

def _registry_extension_impl(mctx):
    bazel_binaries(
        name = "registry_bazel",
        versions = _collect_versions(mctx, "bazel"),
    )
    bazel_registry(
        name = "registry_rules_cc",
        module_name = "rules_cc",
        url_template = "https://github.com/bazelbuild/rules_cc/releases/download/{0}/rules_cc-{0}.tar.gz",
        versions = _collect_versions(mctx, "rules_cc"),
    )
    bazel_registry(
        name = "registry_rules_python",
        module_name = "rules_python",
        url_template = "https://github.com/bazel-contrib/rules_python/releases/download/{0}/rules_python-{0}.tar.gz",
        versions = _collect_versions(mctx, "rules_python"),
    )
    bazel_registry(
        name = "registry_rules_java",
        module_name = "rules_java",
        url_template = "https://github.com/bazelbuild/rules_java/releases/download/{0}/rules_java-{0}.tar.gz",
        versions = _collect_versions(mctx, "rules_java"),
    )

registry = module_extension(
    implementation = _registry_extension_impl,
    tag_classes = {"install": _install},
)
