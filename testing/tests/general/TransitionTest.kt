package com.intellij.aspect.testing.tests.general

import com.google.common.truth.Truth.assertThat
import com.intellij.aspect.testing.rules.AspectFixture
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4

@RunWith(JUnit4::class)
class TransitionTest {

  @Rule
  @JvmField
  val aspect = AspectFixture()

  @Test
  fun testFindTargets() {
    val targets = aspect.findTargets("//:main")
    assertThat(targets).hasSize(3)

    // TODO: add test for configuration hash
  }
}