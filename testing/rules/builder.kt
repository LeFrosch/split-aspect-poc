/*
 * Copyright 2025 The Bazel Authors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.intellij.aspect.testing.rules

import com.google.devtools.intellij.ideinfo.IdeInfo.TargetIdeInfo
import com.google.protobuf.TextFormat
import com.intellij.aspect.private.lib.executeBuild
import com.intellij.aspect.private.lib.executeCommand
import com.intellij.aspect.testing.rules.BuilderProto.BuilderInput
import com.intellij.aspect.testing.rules.BuilderProto.BuilderOutput
import java.io.IOException
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption

private val OUTPUT_GROUPS = listOf("intellij-info")

fun main(args: Array<String>) {
  val input = readInput(args)

  val project = extractTar(input.projectTar)
  val modules = input.modulesList.associate { it.name to extractTar(it.archive) }

  generateModuleFile(project, modules)

  // create a relative output root to not leave the sandbox
  val outputDir = Files.createTempDirectory(Path.of("."), "bazel-output-").toAbsolutePath()

  val files = executeBuild(
    workspaceRoot = project,
    startupFlags = listOf("--output_user_root=$outputDir"),
    bazelExecutable = Path.of(input.bazel.executable).toAbsolutePath().toString(),
    aspects = input.aspectsList,
    outputGroups = OUTPUT_GROUPS,
    targets = input.targetsList,
  )
  require(files.isNotEmpty()) { "no files were generated" }

  val builder = BuilderOutput.newBuilder()
  input.modulesList.map { "${it.name}:${it.version}" }.forEach(builder::addModules)
  files.map(::readInfoFile).forEach(builder::addTargets)
  builder.bazelVersion = input.bazel.version

  Files.newOutputStream(Path.of(input.outputFile)).use { outputStream ->
    builder.build().writeTo(outputStream)
  }
}

private fun readInput(args: Array<String>): BuilderInput {
  val builder = BuilderInput.newBuilder()
  TextFormat.Parser.newBuilder().build().merge(args[0], builder)

  return builder.build()
}

@Throws(IOException::class)
private fun extractTar(archive: String): Path {
  val directory = Files.createTempDirectory(Path.of("."), "archive").toAbsolutePath()

  executeCommand(
    "tar",
    "-xzf", archive,
    "-C", directory.toString(),
    "--preserve-permissions",
    "--strip-components", "1",
  )

  return directory
}

@Throws(IOException::class)
private fun generateModuleFile(project: Path, dependencies: Map<String, Path>) {
  Files.newOutputStream(project.resolve("MODULE.bazel"), StandardOpenOption.CREATE).bufferedWriter().use { writer ->
    for ((name, path) in dependencies) {
      writer.appendLine("bazel_dep(name = '$name')")
      writer.appendLine("local_path_override(module_name = '$name', path = '$path')")
    }
  }
}

@Throws(IOException::class)
private fun readInfoFile(path: Path): TargetIdeInfo {
  Files.newInputStream(path).use { input ->
    val builder = TargetIdeInfo.newBuilder()
    TextFormat.Parser.newBuilder().build().merge(InputStreamReader(input, StandardCharsets.UTF_8), builder)

    return builder.build()
  }
}
