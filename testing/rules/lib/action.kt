package com.intellij.aspect.testing.rules.lib

import com.fasterxml.jackson.databind.ObjectMapper
import com.google.protobuf.Message
import com.google.protobuf.TextFormat
import java.io.BufferedWriter
import java.io.IOException
import java.net.URI
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import kotlin.io.path.toPath

private val MAPPER = ObjectMapper()

@Throws(IOException::class)
inline fun <reified T : Message> action(args: Array<String>, crossinline block: ActionContext.(T) -> Unit) {
  val builder = T::class.java.getMethod("newBuilder").invoke(null) as Message.Builder
  TextFormat.Parser.newBuilder().build().merge(args[0], builder)

  block(ActionContext(), builder.build() as T)
}

class ActionContext {

  val projectDirectory: Path by lazy { tempDirectory("project") }

  val repoCacheDirectory: Path by lazy { tempDirectory("repo_cache") }

  val outputRootDirectory: Path by lazy { tempDirectory("output_root") }

  @Throws(IOException::class)
  fun tempDirectory(name: String): Path {
    return Files.createDirectories(Path.of(name)).toAbsolutePath()
  }

  @Throws(IOException::class)
  fun tempFile(name: String): Path {
    return tempDirectory("temp").resolve(name)
  }

  @Throws(IOException::class)
  fun deployProject(project: String) = unzip(Path.of(project), projectDirectory)

  @Throws(IOException::class)
  fun deployRepoCache(archive: String) = unzip(Path.of(archive), repoCacheDirectory)

  @Throws(IOException::class)
  fun archiveRepoCache(archive: String) = zip(repoCacheDirectory, Path.of(archive))

  @Throws(IOException::class)
  fun writeModule(block: BufferedWriter.() -> Unit) =
    Files.newOutputStream(
      projectDirectory.resolve("MODULE.bazel"),
      StandardOpenOption.CREATE,
      StandardOpenOption.TRUNCATE_EXISTING,
    )
      .bufferedWriter()
      .use(block)

  fun bazelBuild(
    bazel: ActionLibProto.BazelBinary,
    targets: List<String>,
    aspects: List<String> = emptyList(),
    outputGroups: List<String> = emptyList(),
    flags: List<String> = emptyList(),
    allowFetch: Boolean = false,
  ): List<Path> {
    val cmd = mutableListOf<String>()
    cmd.add(Path.of(bazel.executable).toAbsolutePath().toString())
    cmd.add("--output_user_root=$outputRootDirectory")
    cmd.add("build")
    cmd.add("--repository_cache=$repoCacheDirectory")

    if (!allowFetch) {
      cmd.add("--nofetch")
    }

    val bepFile = tempFile("build.bep.json")
    cmd.add("--build_event_json_file=$bepFile")

    if (aspects.isNotEmpty()) {
      cmd.add("--aspects=" + aspects.joinToString(","))
    }

    if (outputGroups.isNotEmpty()) {
      cmd.add("--output_groups=" + outputGroups.joinToString(","))
    }

    cmd.addAll(flags)
    cmd.addAll(targets)

    val process = ProcessBuilder(cmd)
      .directory(projectDirectory.toFile())
      .start()

    val exitCode = process.waitFor()
    if (exitCode != 0) {
      process.errorStream.transferTo(System.err)
      throw IOException("Command failed: ${cmd.joinToString(" ")}")
    }

    return Files.newBufferedReader(bepFile).use { reader ->
      reader.lineSequence().flatMap(::parseBepEvent).distinct().toList()
    }
  }
}

@Throws(IOException::class)
private fun zip(srcDirectory: Path, outFile: Path) {
  ZipOutputStream(Files.newOutputStream(outFile, StandardOpenOption.CREATE)).use { out ->
    Files.walk(srcDirectory).use { stream ->
      stream.filter(Files::isRegularFile).forEach { file ->
        val relativePath = srcDirectory.relativize(file).toString().replace('\\', '/')
        out.putNextEntry(ZipEntry(relativePath))
        Files.newInputStream(file).use { it.transferTo(out) }
      }
    }
  }
}

@Throws(IOException::class)
private fun unzip(srcFile: Path, outDirectory: Path) {
  ZipInputStream(Files.newInputStream(srcFile)).use { src ->
    for (entry in generateSequence { src.nextEntry }) {
      if (!entry.isDirectory) {
        val path = outDirectory.resolve(entry.name)
        Files.createDirectories(path.parent)
        Files.newOutputStream(path, StandardOpenOption.CREATE).use(src::transferTo)
      }
    }
  }
}

/**
 * Parses a single BEP JSON event and extracts file URIs from the
 * namedSetOfFiles.files array.
 */
private fun parseBepEvent(event: String): List<Path> {
  val root = MAPPER.readTree(event)
  val files = root.get("namedSetOfFiles")?.get("files") ?: return emptyList()

  return files.mapNotNull { it.get("uri")?.asText() }.map { URI(it).toPath() }
}
