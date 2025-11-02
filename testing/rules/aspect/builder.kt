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
package com.intellij.aspect.testing.rules.aspect

import com.google.devtools.intellij.AspectFixture.*
import com.google.devtools.intellij.ideinfo.IdeInfo.*
import com.google.protobuf.TextFormat
import java.io.IOException
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.name

private const val IDE_INFO_FILE_OUTPUT_GROUP = "intellij-info"

fun main(args: Array<String>) {
  val inputFiles = args.filter { it.startsWith("@") }.associate(::mapInputFile)
  val outputFile = args.first { !it.startsWith("@") }

  val infoInputFile = requireNotNull(inputFiles[IDE_INFO_FILE_OUTPUT_GROUP])

  val builder = IntellijAspectTestFixture.newBuilder()
  Files.readString(infoInputFile).lines().map(::readInfoFile).forEach(builder::addTargets)
  inputFiles.values.map(::readGroupFile).forEach(builder::addOutputGroups)

  Files.newOutputStream(Path.of(outputFile)).use { outputStream ->
    builder.build().writeTo(outputStream)
  }
}

@Throws(IOException::class)
private fun readInfoFile(path: String): TargetIdeInfo {
  Files.newInputStream(Path.of(path)).use { inputStream ->
    val builder = TargetIdeInfo.newBuilder()
    TextFormat.Parser.newBuilder().build().merge(InputStreamReader(inputStream, StandardCharsets.UTF_8), builder)

    return builder.build()
  }
}

@Throws(IOException::class)
private fun readGroupFile(path: Path): OutputGroup {
  return OutputGroup.newBuilder()
    .setName(path.name)
    .addAllFilePaths(Files.readAllLines(path))
    .build()
}

private fun mapInputFile(arg: String): Pair<String, Path> {
  val path = Path.of(arg.removePrefix("@"))
  return path.name to path
}
