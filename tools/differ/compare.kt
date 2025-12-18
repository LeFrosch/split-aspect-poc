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
package com.intellij.aspect.tools.differ

import com.google.devtools.intellij.ideinfo.IdeInfo.TargetIdeInfo
import com.google.devtools.intellij.ideinfo.IdeInfo.TargetKey
import com.google.protobuf.Descriptors
import com.google.protobuf.Message

/**
 * Represents a difference between two protobuf messages.
 * Nodes recursively build field paths like "parent/child/field".
 */
sealed interface Difference {
  val path: String
  val msg: String

  class Leaf(override val msg: String) : Difference {
    override val path: String get() = ""
  }

  class Node(private val name: String, private val next: Difference) : Difference {
    override val path: String get() = name + "/" + next.path
    override val msg: String get() = next.msg
  }
}

/**
 * Uses reflection to access the static getDescriptor() method for generic
 * protobuf introspection.
 */
private fun Message.getDescriptor(): Descriptors.Descriptor {
  return requireNotNull(javaClass.getMethod("getDescriptor").invoke(null) as? Descriptors.Descriptor)
}

private fun compare(legacy: Any, current: Any): Difference? {
  require(legacy.javaClass == current.javaClass)

  return when (legacy) {
    is TargetKey -> compareField(legacy, current as TargetKey, "label")
    is Message -> compareMessage(legacy, current as Message)
    else -> compareDefault(legacy, current)
  }
}

private fun compareField(legacy: Message, current: Message, name: String): Difference? {
  return compareField(legacy, current, legacy.getDescriptor().findFieldByName(name))
}

/**
 * Bidirectional list comparison: checks that every legacy item exists in
 * current and vice versa.
 */
private fun compareList(legacy: List<*>, current: List<*>): Difference? {
  for (legacyItem in legacy.filterNotNull()) {
    if (current.filterNotNull().none { compare(legacyItem, it) == null }) {
      return Difference.Leaf("missing $legacyItem")
    }
  }

  for (currentItem in current.filterNotNull()) {
    if (legacy.filterNotNull().none { compare(it, currentItem) == null }) {
      return Difference.Leaf("superfluous $currentItem")
    }
  }

  return null
}

/**
 * Compares a single protobuf field: uses list comparison for repeated fields,
 * direct comparison otherwise.
 */
private fun compareField(legacy: Message, current: Message, descriptor: Descriptors.FieldDescriptor): Difference? {
  return if (!descriptor.isRepeated) {
    compare(legacy.getField(descriptor), current.getField(descriptor))
  } else {
    compareList(legacy.getField(descriptor) as List<*>, current.getField(descriptor) as List<*>)
  }?.let { Difference.Node(descriptor.name, it) }
}

private fun compareMessage(legacy: Message, current: Message): Difference? {
  return legacy.getDescriptor().fields.firstNotNullOfOrNull {
    compareField(legacy, current, it)
  }
}

private fun compareDefault(legacy: Any, current: Any): Difference? {
  return if (legacy == current) null else Difference.Leaf("'$legacy' != '$current'")
}

data class Comparison(
  val differences: Map<String, Difference>,
  val common: List<TargetIdeInfo>,
  val missing: List<TargetIdeInfo>,
  val additional: List<TargetIdeInfo>
)

fun compareTargets(legacy: List<TargetIdeInfo>, current: List<TargetIdeInfo>): Comparison {
  val legacyByKey = legacy.associateBy { it.key.label }
  val currentByKey = current.associateBy { it.key.label }

  val commonKeys = legacyByKey.keys.intersect(currentByKey.keys)

  val differences = mutableMapOf<String, Difference>()
  val common = mutableListOf<TargetIdeInfo>()

  for (key in commonKeys) {
    val diff = compare(legacyByKey[key]!!, currentByKey[key]!!)

    if (diff != null) {
      differences[key] = diff
    } else {
      common.add(legacyByKey[key]!!)
    }
  }

  return Comparison(
    common = common,
    differences = differences,
    missing = (legacyByKey.keys - currentByKey.keys).map { legacyByKey[it]!! },
    additional = (currentByKey.keys - legacyByKey.keys).map { currentByKey[it]!! }
  )
}
