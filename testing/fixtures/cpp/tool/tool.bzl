def _file_writer_impl(ctx):
    tool_executable = ctx.executable._tool
    output_file = ctx.actions.declare_file(ctx.attr.out_file)

    ctx.actions.run(
        outputs = [output_file],
        inputs = depset([tool_executable]),
        executable = tool_executable,
        arguments = [output_file.path],
        mnemonic = "FileWriter",
        progress_message = "Writing file %s" % output_file.short_path,
    )

    return [DefaultInfo(files = depset([output_file]))]

file_writer = rule(
    implementation = _file_writer_impl,
    attrs = {
        "out_file": attr.string(mandatory = True),
        "_tool": attr.label(
            default = Label("//:tool"),
            cfg = "exec",
            executable = True,
        ),
    },
)
