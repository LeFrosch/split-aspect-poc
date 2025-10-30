load(":version_repo.bzl", "version_repo")

def _extension_impl(mctx):
    version_repo(name = "bazel_version")

version_extension = module_extension(
    implementation = _extension_impl,
)
