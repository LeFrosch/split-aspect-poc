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
package com.intellij.aspect.testing.rules.integration

import com.fasterxml.jackson.databind.ObjectMapper
import com.google.devtools.intellij.ideinfo.IdeInfo.TargetIdeInfo
import com.google.protobuf.TextFormat
import com.intellij.aspect.testing.rules.integration.BuilderProto.BuilderInput
import com.intellij.aspect.testing.rules.integration.BuilderProto.BuilderOutput
import java.io.IOException
import java.io.InputStreamReader
import java.net.URI
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption
import kotlin.io.path.name
import kotlin.io.path.toPath

private val ASPECTS = listOf(
  "@intellij_aspect//modules:cc_info.bzl%intellij_cc_info_aspect",
  "@intellij_aspect//modules:py_info.bzl%intellij_py_info_aspect",
  "@intellij_aspect//intellij:aspect.bzl%intellij_info_aspect",
)

private val MAPPER = ObjectMapper()

fun main(args: Array<String>) {
  val input = readInput(args)

  val project = extractArchive(input.projectZip)

  val overrides = input.overridesList.associate { it.name to extractArchive(it.archive) }
  generateModuleFile(project, overrides)

  val files = runBazelBuild(input.bazelExecutable, project)

  val builder = BuilderOutput.newBuilder()
  files.map(::readInfoFile).forEach(builder::addTargets)

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
private fun extractArchive(archive: String): Path {
  val directory = Files.createTempDirectory(Path.of(""), "archive-").toAbsolutePath()

  if (archive.endsWith(".zip")) {
    execute(
      "unzip",
      "-q",
      "-o", archive,
      "-d", directory.toString(),
    )
  } else {
    execute(
      "tar",
      "-xzf", archive,
      "-C", directory.toString(),
      "--preserve-permissions",
      // simple heuristic to remove top-level directory from fetched rules
      "--strip-components", "1",
    )
  }

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
private fun runBazelBuild(bazelExecutable: String, project: Path): List<Path> {
  val bepFile = Files.createTempFile(Path.of(""), "bazel-build-", ".bep.json").toAbsolutePath()

  val cmd = listOf(
    Path.of(bazelExecutable).toAbsolutePath().toString(),
    "build",
    "//...",
    "--aspects=" + ASPECTS.joinToString(","),
    "--build_event_json_file=" + bepFile.toString(),
    "--output_groups=intellij-info",
  )

  execute(cmd, pwd = project)

  if (!Files.exists(bepFile)) {
    throw IOException("bep file was not created")
  }

  return Files.newBufferedReader(bepFile).use { reader ->
    reader.lineSequence().flatMap(::parseBepEvent).toList()
  }
}

private fun parseBepEvent(event: String): List<Path> {
  val root = MAPPER.readTree(event)
  val files = root.get("namedSetOfFiles")?.get("files") ?: return emptyList()

  return files.mapNotNull { it.get("uri")?.asText() }.map { URI(it).toPath() }
}

@Throws(IOException::class)
private fun execute(vararg cmd: String) = execute(cmd.toList(), Path.of("."))

@Throws(IOException::class)
private fun execute(cmd: List<String>, pwd: Path) {
  val process = ProcessBuilder(cmd)
    .directory(pwd.toFile())
    .inheritIO()
    .start()

  val exitCode = process.waitFor()
  if (exitCode != 0) {
    throw IOException("command failed: ${cmd.joinToString(" ")}")
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
