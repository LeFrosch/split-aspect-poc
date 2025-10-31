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
package com.intellij.aspect.testing.tests.general.transition

import com.google.common.truth.Truth.assertThat
import com.intellij.aspect.testing.utils.IntellijAspectResource
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4

@RunWith(JUnit4::class)
class TransitionTest {

  @Rule
  @JvmField
  val aspect = IntellijAspectResource()

  @Test
  fun testFindTargets() {
    val targets = aspect.findTargets(":simple")
    assertThat(targets).hasSize(2)

    // TODO: add test for configuration hash
  }
}
