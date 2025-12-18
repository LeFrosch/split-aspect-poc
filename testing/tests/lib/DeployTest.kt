package com.intellij.aspect.testing.tests.lib

import com.google.common.truth.Truth.assertThat
import com.google.devtools.build.runfiles.Runfiles
import com.intellij.aspect.private.lib.AspectConfig
import com.intellij.aspect.private.lib.deployAspectZip
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path

private val RUNFILES = Runfiles.preload()

@RunWith(JUnit4::class)
class DeployTest {

  @Throws(IOException::class)
  private fun deployArchive(): Path {
    val archive = requireNotNull(System.getenv("ARCHIVE_IDE"))
    val tempdir = requireNotNull(System.getenv("TEST_TMPDIR"))

    val relativeDestination = Path.of("aspect").resolve("location")

    deployAspectZip(
      workspaceRoot = Path.of(tempdir),
      relativeDestination = relativeDestination,
      archiveZip = Path.of(RUNFILES.unmapped().rlocation(archive)),
      config = AspectConfig(bazelVersion = "8.5.0"),
    )

    return Path.of(tempdir).resolve(relativeDestination)
  }

  @Test
  fun testDeployArchive() {
    deployArchive()
  }

  @Test
  fun testRewritesLoadStatement() {
    val path = deployArchive()

    val aspectFile = path.resolve("intellij").resolve("aspect.bzl")
    val aspectText = Files.readString(aspectFile)

    assertThat(aspectText).contains("load(\"//aspect/location/common:artifact_location.bzl\"")
  }
}