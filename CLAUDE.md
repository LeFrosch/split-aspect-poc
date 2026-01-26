# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a proof-of-concept for a modular Bazel aspect system designed for IntelliJ/CLion IDE integration. The goal is to replace the current templated aspect with a non-templated, modular version that can be published to the Bazel Central Registry (BCR).

**Key Goals:**
- Eliminate templating to enable BCR publishing
- Support cacheable outputs for faster IDE imports
- Modular architecture with language-specific aspects
- Drop-in replacement for existing IDE aspect

## Build Commands

```bash
# Build all targets
bazel build //...

# Run all tests
bazel test //...

# Build BCR archive (for publishing to BCR)
bazel build //:archive_bcr

# Build IDE archive (for IDE materialization)
bazel build //:archive_ide

# Run specific test suite
bazel test //testing/tests/cpp/...
bazel test //testing/tests/python/...
bazel test //testing/tests/java/...
```

## Architecture

### Three-Layer Aspect System

1. **Module Aspects** (`modules/`)
   - Language-specific aspects: `cc_info.bzl`, `py_info.bzl`, `java_info.bzl`
   - Toolchain aspects: `cc_toolchain_info.bzl`, `java_toolchain_info.bzl`, `xcode_info.bzl`
   - Each produces a normalized provider with `value`, `outputs`, `dependencies`, and `toolchains`
   - Use `provides = [<provider>]` to advertise their presence to the aggregator
   - Can be dynamically toggled from command line

2. **Aggregator Aspect** (`intellij/aspect.bzl`)
   - Main `intellij_info_aspect` that merges module providers
   - Collects all present module providers via `required_aspect_providers`
   - Serializes combined data to a single `.intellij-info.txt` textproto per target
   - Handles dependency edges and output groups

3. **Common Utilities** (`common/`)
   - Shared aspect infrastructure
   - `common.bzl`: Core aspect utilities and TargetInfo provider
   - `dependencies.bzl`: Dependency collection and typing
   - `ide_info.bzl`: Textproto serialization
   - `artifact_location.bzl`: File path handling
   - `make_variables.bzl`: Toolchain variable expansion
   - `version.bzl`: Bazel version compatibility checks

### Propagation Model

- All aspects use `attr_aspects=["*"]` to traverse the entire build graph
- Language and toolchain aspects use `toolchains_aspects=[...]` to traverse toolchain edges
- Module aspects declare `provides = [<provider>]` for dynamic visibility
- Toolchain aspects write their own `.intellij-info.txt` files independently

### Module Provider Interface

See `modules/provider.bzl` for the provider definitions:
- Module providers: `IntelliJCcInfo`, `IntelliJPyInfo`, `IntelliJJavaInfo`
- Toolchain providers: `IntelliJCcToolchainInfo`, `IntelliJXcodeToolchainInfo`, `IntelliJJavaToolchainInfo`
- Each has `present` field to indicate if applicable to target
- Use `intellij_provider.create()` to construct module providers
- Use `intellij_provider.create_toolchain()` for toolchain providers

## Testing Infrastructure

### Test Structure

- **Fixtures** (`testing/fixtures/`): Small Bazel projects for each language (cpp, python, java)
- **Tests** (`testing/tests/`): Kotlin test suites that validate aspect output
- **Rules** (`testing/rules/`): Test framework and builder binary

### Test Approach

Tests use a builder binary (`//testing/rules:builder_bin`) that:
1. Builds fixtures with the aspect applied
2. Collects all `.intellij-info.txt` outputs
3. Parses textprotos and serializes to a single proto for validation
4. Kotlin tests load this proto via runfiles and assert on structure

### Running Tests Against Multiple Versions

The `private/extension.bzl` registry extension configures tests to run against multiple versions:
- Bazel versions: 7.7.0, 8.5.1, 9.0.0
- rules_cc versions: 0.1.1, 0.2.9, 0.2.14
- rules_java versions: 8.16.1, 9.3.0
- rules_python versions: 1.4.0, 1.6.3, 1.7.0

## Deployment Modes

The aspect supports two deployment modes:

1. **From BCR** (preferred)
   - Aspect fetched as regular bzlmod dependency
   - Users add to MODULE.bazel: `bazel_dep(name = "intellij_aspect", version = "x.y.z")`
   - No templating required
   - Dependencies on rule sets declared in MODULE.bazel.bcr

2. **Materialized by IDE** (fallback)
   - IDE writes aspect files into `.ijwb/aspects/` or similar
   - Minimal templating: rewrite load statements and generate config file
   - Allows IDE to control aspect version for compatibility

Configuration is managed by `config/config.bzl` which differs between modes.

## Key Files and Directories

- `MODULE.bazel`: Bazel module definition with dependencies
- `MODULE.bazel.bcr`: Template for BCR publication (substitutes version)
- `BUILD`: Creates `archive_bcr` and `archive_ide` distribution packages
- `.bazelrc`: Prefers prebuilt protoc for faster builds
- `.bazelversion`: Currently using Bazel 9.0.0
- `private/proto/`: Protobuf schema for `.intellij-info.txt` files
- `private/lib/`: Java utilities for test framework
- `tools/`: Build tool scripts

## Important Design Considerations

### Backward Compatibility
- Aspect handles both Bazel 7 (old toolchain deps) and Bazel 8+ (toolchain types)
- Uses `getattr()` and guarded feature reads for forward compatibility
- Toolchain aspects support both regular dependencies and specialized toolchain dependencies

### Performance
- Traversing entire graph with `attr_aspects=["*"]` increases analysis work
- Module aspects perform fast "present" checks to skip irrelevant targets
- Targets under exec configuration are ignored to avoid unnecessary builds

### Version Compatibility
- When aspect is from BCR, IDE must handle version compatibility
- Can fall back to materializing aspect if BCR version incompatible
- Use BCR's `compatibility_level` for breaking changes

## Adding a New Language Module

1. Create new aspect in `modules/<lang>_info.bzl`
2. Define provider in `modules/provider.bzl` (add to `_MODULE_PROVIDERS`)
3. Aspect should check for language-specific providers (e.g., `PyInfo`, `CcInfo`, `JavaInfo`)
4. Return `intellij_provider.create()` with module-specific data structure
5. Add aspect to `requires` list in `intellij/aspect.bzl`
6. Create test fixtures in `testing/fixtures/<lang>/`
7. Write Kotlin tests in `testing/tests/<lang>/`
8. Update `modules/BUILD` to include new .bzl file
