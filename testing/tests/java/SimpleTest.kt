package com.intellij.aspect.testing.tests.java

import com.google.common.truth.Truth.assertThat
import com.intellij.aspect.testing.rules.AspectFixture
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4

@RunWith(JUnit4::class)
class SimpleTest {

    @Rule
    @JvmField
    val aspect = AspectFixture()

    @Test
    fun testFindsMain() {
        val target = aspect.findTarget("//:main")
        assertThat(target.hasJavaIdeInfo()).isTrue()
        assertThat(target.kindString).isEqualTo("java_binary")

        // Sources are reported correctly
        assertThat(target.javaIdeInfo.sourcesList.size).isEqualTo(1)
        assertThat(target.javaIdeInfo.sourcesList[0].isSource).isTrue()
        assertThat(target.javaIdeInfo.sourcesList[0].relativePath).isEqualTo("Main.java")

        // Dependencies are reported correctly
        assertThat(target.depsList.size).isEqualTo(1)
        assertThat(target.depsList[0].target.label).isEqualTo("//lib:util")
    }

    @Test
    fun testFindsLib() {
        val target = aspect.findTarget("//lib:util")
        assertThat(target.hasJavaIdeInfo()).isTrue()
        assertThat(target.kindString).isEqualTo("java_library")

        // Sources are reported correctly
        assertThat(target.javaIdeInfo.sourcesList.size).isEqualTo(1)
        assertThat(target.javaIdeInfo.sourcesList[0].isSource).isTrue()
        assertThat(target.javaIdeInfo.sourcesList[0].relativePath).isEqualTo("lib/Util.java")
    }
}