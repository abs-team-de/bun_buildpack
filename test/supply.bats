#!/usr/bin/env bats
# ================================================================
# Tests for bin/supply
#
# Supply requires network access to download Bun. These tests mock
# the download by pre-staging a cached zip or by testing isolated
# logic paths.
# ================================================================

load test_helper/common_setup

setup() {
  setup_common
  # Create bun install directory that supply would create
  mkdir -p "${DEPS_DIR}/${DEPS_IDX}/bun/bin"
  mkdir -p "${DEPS_DIR}/${DEPS_IDX}/bin"
  mkdir -p "${DEPS_DIR}/${DEPS_IDX}/profile.d"
}

teardown() {
  teardown_common
}

@test "supply: reads version from engines.bun in package.json" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1.2.9"}}'
  # Pre-stage cached zip to avoid network
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  # Skip checksum for this test
  BUN_SKIP_CHECKSUM=true run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bun version: v1.2.9"* ]]
}

@test "supply: BUN_OVERRIDE_VERSION takes precedence over engines.bun" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1.1.0"}}'
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  BUN_OVERRIDE_VERSION=1.2.9 BUN_SKIP_CHECKSUM=true run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bun version: v1.2.9"* ]]
}

@test "supply: falls back to BUN_DEFAULT_VERSION when no version specified" {
  create_package_json "$BUILD_DIR" '{"name":"test","version":"1.0.0"}'
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  BUN_SKIP_CHECKSUM=true run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bun version: v1.2.9 (requested: 'not set')"* ]]
}

@test "supply: fails on unsupported version format" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1"}}'

  run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported engines.bun"* ]]
}

@test "supply: cache reuse — uses cached zip without download" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1.2.9"}}'
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  BUN_SKIP_CHECKSUM=true run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Using cached Bun v1.2.9"* ]]
}

@test "supply: profile.d script is generated with correct content" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1.2.9"}}'
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  BUN_SKIP_CHECKSUM=true run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]

  # Check profile.d was created in both locations
  [ -f "${DEPS_DIR}/${DEPS_IDX}/profile.d/000_bun.sh" ]
  [ -f "${BUILD_DIR}/.profile.d/000_bun.sh" ]

  # Check DEPS_IDX placeholder was replaced
  run grep "__DEPS_IDX__" "${DEPS_DIR}/${DEPS_IDX}/profile.d/000_bun.sh"
  [ "$status" -eq 1 ]  # grep should NOT find the placeholder

  # Check actual DEPS_IDX value is present
  run grep "${DEPS_IDX}" "${DEPS_DIR}/${DEPS_IDX}/profile.d/000_bun.sh"
  [ "$status" -eq 0 ]
}

@test "supply: bun binary is installed and executable" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1.2.9"}}'
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  BUN_SKIP_CHECKSUM=true run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]

  # Check bun binary exists and is executable
  [ -x "${DEPS_DIR}/${DEPS_IDX}/bun/bin/bun" ]
}

@test "supply: checksum verification with BUN_DOWNLOAD_SHA256" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1.2.9"}}'
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  # Compute actual SHA256 of the fixture
  ACTUAL_SHA=$(sha256sum "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip" | awk '{print $1}')

  BUN_DOWNLOAD_SHA256="$ACTUAL_SHA" run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SHA256 checksum verified"* ]]
}

@test "supply: checksum mismatch fails staging" {
  create_package_json "$BUILD_DIR" '{"name":"test","engines":{"bun":"1.2.9"}}'
  create_bun_zip_fixture "${CACHE_DIR}/bun-v1.2.9-linux-x64.zip"

  BUN_DOWNLOAD_SHA256="0000000000000000000000000000000000000000000000000000000000000000" run "${BUILDPACK_DIR}/bin/supply" "$BUILD_DIR" "$CACHE_DIR" "$DEPS_DIR" "$DEPS_IDX"
  [ "$status" -eq 1 ]
  [[ "$output" == *"SHA256 checksum mismatch"* ]]
}
