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
package com.intellij.aspect.tools.differ

import com.google.devtools.intellij.ideinfo.IdeInfo.TargetIdeInfo
import com.google.protobuf.TextFormat
import kotlinx.cli.ArgParser
import kotlinx.cli.ArgType
import kotlinx.cli.default
import java.io.IOException
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import kotlin.system.exitProcess

private val SEPARATOR = "=".repeat(80)

fun main(args: Array<String>) {
  val parser = ArgParser("differ")

  val projectPath by parser.argument(
    ArgType.String,
    description = "Path to the Bazel project to analyze"
  )

  val bazelExecutable by parser.option(
    ArgType.String,
    shortName = "b",
    fullName = "bazel",
    description = "Path to bazel executable"
  ).default("bazel")

  val targetPattern by parser.option(
    ArgType.String,
    shortName = "t",
    fullName = "targets",
    description = "Target pattern to build"
  ).default("//...")

  val verbose by parser.option(
    ArgType.Boolean,
    shortName = "v",
    fullName = "verbose",
    description = "Show detailed progress and stack traces"
  ).default(false)

  parser.parse(args)

  try {
    System.err.println("Running differ on project: $projectPath")

    // set up the temporary workspace
    TemporaryWorkspace(Path.of(projectPath), bazelExecutable).use { workspace ->
      System.err.println("Deploying legacy aspect...")
      workspace.deployLegacyAspect()

      val legacyFiles = workspace.runLegacyAspect(targetPattern)
      val legacyTargets = loadTargets(legacyFiles)
      System.err.println("Legacy aspect generated: ${legacyFiles.size} files")

      System.err.println("Deploying current aspect...")
      workspace.deployCurrentAspect()

      val currentFiles = workspace.runCurrentAspect(targetPattern)
      val currentTargets = loadTargets(currentFiles)
      System.err.println("Current aspect generated: ${currentFiles.size} files")

      System.err.println("Comparing...")
      val result = compareTargets(legacyTargets, currentTargets)

      println(reportComparison(result))

      if (result.differences.isEmpty() && result.missing.isEmpty()) {
        exitProcess(0)
      } else {
        exitProcess(1)
      }
    }
  } catch (e: Exception) {
    System.err.println("Error: ${e.message}")
    if (verbose) {
      e.printStackTrace()
    }

    exitProcess(2)
  }
}

@Throws(IOException::class)
fun loadTargets(files: List<Path>): List<TargetIdeInfo> {
  return files.map { path ->
    Files.newInputStream(path).use { input ->
      val builder = TargetIdeInfo.newBuilder()
      TextFormat.Parser.newBuilder().build().merge(InputStreamReader(input, StandardCharsets.UTF_8), builder)
      builder.build()
    }
  }
}

private fun reportComparison(result: Comparison): String {
  val sb = StringBuilder()

  sb.appendLine("TARGET SUMMARY")
  sb.appendLine(SEPARATOR)
  sb.appendLine("  Common:     ${result.common.size}")
  sb.appendLine("  Missing:    ${result.missing.size}")
  sb.appendLine("  Additional: ${result.additional.size}")
  sb.appendLine("  Different:  ${result.differences.size}")
  sb.appendLine()

  if (result.missing.isNotEmpty()) {
    sb.appendLine("MISSING TARGETS (${result.missing.size})")
    sb.appendLine(SEPARATOR)
    result.missing.forEach { target ->
      sb.appendLine("  ${target.key.label}")
    }
    sb.appendLine()
  }

  if (result.additional.isNotEmpty()) {
    sb.appendLine("ADDITIONAL TARGETS (${result.additional.size})")
    sb.appendLine(SEPARATOR)
    result.additional.forEach { target ->
      sb.appendLine("  ${target.key.label}")
    }
    sb.appendLine()
  }

  if (result.differences.isNotEmpty()) {
    sb.appendLine("DIFFERENCES (${result.differences.size})")
    sb.appendLine(SEPARATOR)
    result.differences.forEach { (label, diff) ->
      val path = diff.path.trimEnd('/')
      sb.appendLine("  $label#$path: ${diff.msg}")
    }
    sb.appendLine()
  }

  if (result.differences.isEmpty() && result.missing.isEmpty()) {
    sb.appendLine("RESULT: OK")
  } else {
    sb.appendLine("RESULT: DIFFERENCES FOUND")
  }
  sb.appendLine(SEPARATOR)

  return sb.toString()
}
