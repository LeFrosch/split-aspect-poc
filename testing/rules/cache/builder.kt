package com.intellij.aspect.testing.rules.cache

import com.intellij.aspect.testing.rules.cache.BuilderProto.BuilderInput
import com.intellij.aspect.testing.rules.lib.action

fun main(args: Array<String>) = action<BuilderInput>(args) { input ->
  deployProject(input.projectArchive)

  for (config in input.configsList) {
    writeModule {
      for (module in config.modulesList) {
        appendLine("bazel_dep(name = '${module.name}', version = '${module.version}')")
      }
    }

    bazelBuild(config.bazel, listOf("//..."), allowFetch = true)
  }

  archiveRepoCache(input.outputArchive)
}