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

import java.nio.file.Path

/**
 * Converts a relative label to a test relative label. The location of the
 * test binary is used as the base path.
 */
fun testRelativeLabel(relativeLabel: String): String {
  require(relativeLabel.startsWith(':'))
  val basePath = Path.of(System.getenv("TEST_BINARY")).parent
  return "//$basePath$relativeLabel"
}

/**
 * Converts a relative path to a test relative path. The location of the
 * test binary is used as the base path.
 */
fun testRelativePath(relativePath: String): String {
  require(!relativePath.startsWith('/'))
  val basePath = Path.of(System.getenv("TEST_BINARY")).parent
  return basePath.resolve(relativePath).toString()
}
