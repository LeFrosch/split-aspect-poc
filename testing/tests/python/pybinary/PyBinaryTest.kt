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
package com.intellij.aspect.testing.tests.python.pybinary

import com.google.common.truth.Truth.assertThat
import com.google.devtools.intellij.ideinfo.IdeInfo.PyIdeInfo.PythonSrcsVersion
import com.google.devtools.intellij.ideinfo.IdeInfo.PyIdeInfo.PythonVersion
import com.intellij.aspect.testing.utils.IntellijAspectResource
import com.intellij.aspect.testing.utils.intellijInfoFileName
import com.intellij.aspect.testing.utils.testRelativePath
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4
import kotlin.io.path.name

@RunWith(JUnit4::class)
class PyBinaryTest {

  @Rule
  @JvmField
  val aspect = IntellijAspectResource()

  @Test
  fun testPy3Binary() {
    val target = aspect.findTarget(":simple3")
    assertThat(target.hasPyIdeInfo()).isTrue()
    assertThat(target.hasCIdeInfo()).isFalse()

    assertThat(target.kindString).isEqualTo("py_binary")
    assertThat(target.pyIdeInfo.sourcesList.map { it.relativePath }).containsExactly(testRelativePath("simple.py"))
    assertThat(target.pyIdeInfo.srcsVersion).isEqualTo(PythonSrcsVersion.SRC_PY2AND3)
    assertThat(target.pyIdeInfo.pythonVersion).isEqualTo(PythonVersion.PY3)

    assertThat(aspect.findInfoOutputGroup().map { it.name}).contains(intellijInfoFileName(target.key))
  }

  @Test
  fun testPyBinaryBuildfileArgs() {
    val info = aspect.findPyIdeInfo(":buildfile_args")
    val compilationMode = System.getenv("COMPILATION_MODE_FOR_TEST")

    assertThat(compilationMode).isNotNull()
    assertThat(info.argsList).containsExactly("--ARG1", "--ARG2=$compilationMode", "--ARG3='with spaces'")
  }

  @Test
  fun testExpandDataDeps() {
    val info = aspect.findPyIdeInfo(":expand_datadeps")
    assertThat(info.argsList).hasSize(1)
    assertThat(info.argsList.first()).endsWith(testRelativePath("datadepfile.txt"))
  }
}