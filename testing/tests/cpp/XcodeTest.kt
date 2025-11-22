package com.intellij.aspect.testing.tests.cpp

import com.google.common.truth.Truth.assertThat
import com.google.devtools.intellij.ideinfo.IdeInfo
import com.google.devtools.intellij.ideinfo.IdeInfo.*
import com.intellij.aspect.testing.rules.AspectFixture
import com.intellij.aspect.testing.rules.isMacOS
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4

@RunWith(JUnit4::class)
class XcodeTest {

  @Rule
  @JvmField
  val aspect = AspectFixture()

  @Before
  fun prerequisites() {
    assumeTrue(aspect.bazelVersion(min = 8))
    assumeTrue(isMacOS())
  }

  @Test
  fun testHasXcodeInfo() {
    val target = aspect.findTarget("//:main").depsList
      .map { aspect.findTarget(it.target.label) }
      .first { it.hasCToolchainIdeInfo() }

    assertThat(target.hasXcodeIdeInfo()).isTrue()
    assertThat(target.xcodeIdeInfo.xcodeVersion).isNotEmpty()
    assertThat(target.xcodeIdeInfo.defaultMacosSdkVersion).isNotEmpty()
  }
}
