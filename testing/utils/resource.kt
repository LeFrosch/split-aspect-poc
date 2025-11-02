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
package com.intellij.aspect.testing.utils

import com.google.devtools.build.runfiles.Runfiles
import com.google.devtools.intellij.AspectFixture.*
import com.google.devtools.intellij.ideinfo.IdeInfo.*
import org.junit.rules.ExternalResource
import java.io.FileInputStream
import java.io.IOException
import java.nio.file.Path

private const val INTELLIJ_INFO_OUTPUT_GROUP = "intellij-info"

/**
 * JUnit resource for loading and accessing intellij aspect test fixtures.
 */
class IntellijAspectResource : ExternalResource() {

  private lateinit var fixture: IntellijAspectTestFixture

  override fun before() {
    fixture = loadAspectFixture()
  }

  fun findTargets(
    label: String,
    externalRepo: String? = null,
    fractionalAspectIds: List<String> = emptyList(),
  ): List<TargetIdeInfo> {
    return fixture.targetsList.filter { matchTarget(it, label, externalRepo, fractionalAspectIds) }
  }

  fun findTarget(
    label: String,
    externalRepo: String? = null,
    fractionalAspectIds: List<String> = emptyList(),
  ): TargetIdeInfo {
    return requireNotNull(findTargets(label, externalRepo, fractionalAspectIds).firstOrNull()) {
      "target not found: $label"
    }
  }

  fun findCIdeInfo(
    label: String,
    externalRepo: String? = null,
    fractionalAspectIds: List<String> = emptyList(),
  ): CIdeInfo {
    val target = findTarget(label, externalRepo, fractionalAspectIds)
    require(target.hasCIdeInfo()) { "target has no c_ide_info: $label" }

    return target.cIdeInfo
  }

  fun findPyIdeInfo(
    label: String,
    externalRepo: String? = null,
    fractionalAspectIds: List<String> = emptyList(),
  ): PyIdeInfo {
    val target = findTarget(label, externalRepo, fractionalAspectIds)
    require(target.hasPyIdeInfo()) { "target has no py_ide_info: $label" }

    return target.pyIdeInfo
  }

  fun findOutputGroup(outputGroup: String): List<Path> {
    val group = fixture.outputGroupsList.firstOrNull { it.name == outputGroup } ?: return emptyList()
    return group.filePathsList.map(Path::of)
  }

  fun findInfoOutputGroup(): List<Path> = findOutputGroup(INTELLIJ_INFO_OUTPUT_GROUP)
}

@Throws(IOException::class)
private fun loadAspectFixture(): IntellijAspectTestFixture {
  val runfiles = Runfiles.preload()
  val fixturePath = runfiles.unmapped().rlocation(System.getenv("ASPECT_FIXTURE"));

  FileInputStream(fixturePath).use { inputStream ->
    return IntellijAspectTestFixture.parseFrom(inputStream)
  }
}

/**
 * Matches a target key, see [matchLabel] and [matchAspectIds] for details.
 */
private fun matchTarget(
  info: TargetIdeInfo,
  label: String,
  externalRepo: String?,
  fractionalAspectIds: List<String>,
): Boolean {
  return info.hasKey()
      && matchLabel(info.key, label, externalRepo)
      && matchAspectIds(info.key, fractionalAspectIds)
}

/**
 * Matches target key against a label. If the label is relative it is treated
 * as a test relative label. If a external repo is specified the label must be
 * absolute with regard to that repo.
 */
private fun matchLabel(key: TargetKey, label: String, externalRepo: String?): Boolean {
  if (externalRepo != null) {
    require(label.startsWith("//")) { "external repo label must be absolute: $label" }
    return key.label.endsWith("$externalRepo$label")
  }
  if (label.startsWith(':')) {
    return key.label == testRelativeLabel(label)
  }

  return key.label == label
}

/**
 * Matches a target key against a list of partial target keys. Returns true if
 * any of the partial keys match or the list is empty.
 */
private fun matchAspectIds(key: TargetKey, fractionalAspectIds: List<String>): Boolean {
  if (fractionalAspectIds.isEmpty()) return true

  for (aspectId in key.aspectIdsList) {
    if (key.aspectIdsList.any { it.contains(aspectId) }) return true
  }

  return false
}
