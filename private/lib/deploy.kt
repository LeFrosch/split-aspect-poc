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
package com.intellij.aspect.private.lib

import java.io.IOException
import java.io.InputStream
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption
import java.util.zip.ZipFile
import kotlin.io.path.extension

/**
 * Regex to match Bazel load statements. Captures:
 * group 1 = path (e.g., "//foo:bar.bzl"),
 * group 2 = symbols (e.g., "symbol1, symbol2")
 */
private val LOAD_STATEMENT_REGEX = Regex("""load\(\s*"([^"]+)"\s*,\s*([^)]+)\)""")

/**
 * Regex to identify repository-relative paths that need rewriting. Matches:
 * //path:file.bzl (but not external @repo paths, which don't start with //)
 */
private val REPO_RELATIVE_PATH_REGEX = Regex("""^//([^:]+):([^"]+)$""")

/**
 * Config for the aspect deployment. Used to generate the config/config.bzl
 * file.
 */
data class AspectConfig(val bazelVersion: String)

/**
 * Deploy an aspect archive to a workspace directory.
 *
 * This function extracts all files from the archive and rewrites their load statements
 * to point to the deployed location.
 *
 * @param workspaceRoot The root directory of the workspace
 * @param relativeDestination The relative path from workspace root where aspect should be deployed
 * @param archiveZip The path to the zip archive containing the aspect files
 * @param config Configuration for the aspect deployment
 * @throws IOException if extraction or file operations fail
 */
@Throws(IOException::class)
fun deployAspectZip(
  workspaceRoot: Path,
  relativeDestination: Path,
  archiveZip: Path,
  config: AspectConfig,
) {
  require(!relativeDestination.isAbsolute)
  require(archiveZip.extension == "zip")

  val destination = workspaceRoot.resolve(relativeDestination)
  Files.createDirectories(destination)

  extractZipArchive(destination, relativeDestination, archiveZip)
  writeAspectConfig(destination, config)
}

@Throws(IOException::class)
private fun extractZipArchive(destination: Path, deployPath: Path, archiveZip: Path) {
  Files.createDirectories(destination)

  ZipFile(archiveZip.toFile()).use { zip ->
    zip.stream().forEach { entry ->
      val target = destination.resolve(entry.name)

      if (entry.isDirectory) {
        Files.createDirectories(target)
      } else {
        Files.writeString(
          target,
          rewriteLoadStatements(zip.getInputStream(entry), deployPath),
          Charsets.UTF_8,
          StandardOpenOption.CREATE,
          StandardOpenOption.TRUNCATE_EXISTING,
          )
      }
    }
  }
}

/**
 * Rewrites all load statements from the input file and returns the rewritten
 * contents. Assumes all files in the archive are UTF-8 encoded text.
 */
@Throws(IOException::class)
private fun rewriteLoadStatements(input: InputStream, deployPath: Path): String {
  val content = String(input.readAllBytes(), Charsets.UTF_8)

  return LOAD_STATEMENT_REGEX.replace(content) { matchResult ->
    val originalPath = matchResult.groupValues[1]
    val symbols = matchResult.groupValues[2]

    val newPath = rewritePath(originalPath, deployPath.toString())

    """load("$newPath", $symbols)"""
  }
}

/**
 * Rewrite a load path if it's a repository-relative path.
 *
 * Repository-relative paths (e.g. //path:file.bzl) are rewritten with the deploy
 * path prefix. Other paths (external dependencies, relative paths) are left
 * unchanged.
 */
private fun rewritePath(originalPath: String, deployPath: String): String {
  val match = REPO_RELATIVE_PATH_REGEX.matchEntire(originalPath) ?: return originalPath

  val packagePath = match.groupValues[1]
  val fileName = match.groupValues[2]

  return "//$deployPath/$packagePath:$fileName"
}

/**
 * Creates the config directory and writes the config file as well as the
 * required BUILD file.
 */
@Throws(IOException::class)
fun writeAspectConfig(destination: Path, config: AspectConfig) {
  val directory = destination.resolve("config")
  Files.createDirectories(directory)

  val buildFile = directory.resolve("BUILD")
  Files.writeString(buildFile, "# generated build file", Charsets.UTF_8)

  val configFile = directory.resolve("config.bzl")
  Files.writeString(configFile, generateConfigStruct(config), Charsets.UTF_8)
}

private fun generateConfigStruct(config: AspectConfig) = """
# generated config file by deployment

config = struct(
	bazel_version = "${config.bazelVersion}",
)
"""
