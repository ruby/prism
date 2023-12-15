#!/bin/bash

set -e

WASI_SDK_VERSION_MAJOR="20"
WASI_SDK_VERSION="$WASI_SDK_VERSION_MAJOR.0"
TMPDIR="$(pwd)/tmp"
WASI_SDK_PATH="${TMPDIR}/wasi-sdk-${WASI_SDK_VERSION}"
WASI_SDK_TAR="${TMPDIR}/wasi-sdk.tar.gz"
WASM_BUILD_DIR="./target/wasm32-wasi/debug/examples"
WASM_FILE="${WASM_BUILD_DIR}/wasm.wasm"

export WASI_SDK_PATH

download_wasi_sdk() {
  if [ -d "${WASI_SDK_PATH}" ]; then
    echo "WASI SDK already downloaded to ${WASI_SDK_PATH}" >&2
    return
  fi

  mkdir -p "${TMPDIR}"

  if [ "$(uname)" == "Darwin" ]; then
    echo "Downloading wasi-sdk for macOS" >&2
    curl -sLo "${WASI_SDK_TAR}" "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION_MAJOR}/wasi-sdk-${WASI_SDK_VERSION}-macos.tar.gz" >&2
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "Downloading wasi-sdk for Linux" >&2
    curl -sLo "${WASI_SDK_TAR}" "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION_MAJOR}/wasi-sdk-${WASI_SDK_VERSION}-linux.tar.gz" >&2
  else
    echo "Unsupported platform" >&2
    exit 1
  fi

  tar -xzf "${WASI_SDK_TAR}" -C "${TMPDIR}" >&2
  echo "WASI SDK downloaded to ${TMPDIR}" >&2
}

build_wasm() {
  cargo build --target=wasm32-wasi --example wasm >&2
  echo "WASM built to ${WASM_FILE}" >&2
}

download_wasi_sdk
build_wasm

if command -v wasmtime >/dev/null 2>&1; then
  for ruby_file in ../../lib/**/*.rb; do
    echo "${ruby_file}"
    wasmtime run "${WASM_FILE}" < "${ruby_file}"
  done
else
  echo "wasmtime not found, skipping run..." >&2
fi
