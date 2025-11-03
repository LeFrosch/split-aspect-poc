ModuleArchive = provider(fields = ["name", "version", "file"])
ModuleArchive = provider(fields = ["name", "versions"])

def _module_archive_impl(ctx):
    return [
        ModuleArchive(
            name = ctx.attr.module_name,
            version = ctx.attr.version,
            src = ctx.file.src,
        ),
        DefaultInfo(files = depset([ctx.file.src])),
    ]

module_archive = rule(
    implementation = _module_archive_impl,
    attrs = {
        "module_name": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
        "src": attr.label(
            allow_single_file = [".tar.gz"],
            mandatory = True,
        ),
    },
)

def _module_set_impl(ctx):
    ctx.attr.deps[]
    return []

module_set = rule(
    implementation = _module_archive_impl,
    attrs = {
        "deps": attr.label_list(
            mandatory = True,
            providers = [ModuleArchive],
        ),
    },
)
