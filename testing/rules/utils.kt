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

import com.google.devtools.intellij.ideinfo.IdeInfo.TargetKey

fun isMacOS(): Boolean = System.getProperty("os.name").lowercase().contains("mac")

fun isLinux(): Boolean = System.getProperty("os.name").lowercase().contains("linux")

fun isWindows(): Boolean = System.getProperty("os.name").lowercase().contains("windows")

/**
 * Calculates the name of the intellij-info file for that target. Reflects the
 * logic in _write_ide_info of aspect.bzl.
 */
fun intellijInfoFileName(key: TargetKey): String {
  val name = key.label.substringAfterLast(':')

  val parts = listOf(key.label, key.configuration) + key.aspectIdsList
  val hash = parts.joinToString(".").hashCode()

  return "$name-$hash.intellij-info.txt"
}