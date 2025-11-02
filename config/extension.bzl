load("@bazel_skylib//lib:versions.bzl", "versions")

def _config_repo_impl(rctx):
    substitutions = {
        "{BAZEL_VERSION}": versions.get(),
    }

    rctx.file("BUILD", "")
    rctx.template("config.bzl", rctx.attr._config_template, substitutions = substitutions)

config_repo = repository_rule(
    implementation = _config_repo_impl,
    local = True,  # force reruns on server restarts to keep native.bazel_version up-to-date.
    attrs = {
        "_config_template": attr.label(
            allow_single_file = True,
            default = Label(":config.tpl"),
        ),
    },
)

def _config_extension_impl(mctx):
    config_repo(name = "intellij_config")

config = module_extension(
    implementation = _config_extension_impl,
)
