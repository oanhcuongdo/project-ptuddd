#!/bin/sh
set -eu

version="9.0.3"
archive="LatinOCRResources.bundle.zip"
checksum="C790283599F67708C06FD93DE61D96823CE2AD984AD00BFDA5922AFDA0861758"
resource_dir="${PROJECT_DIR}/mlkit_bundles"
bundle_dir="${resource_dir}/LatinOCRResources.bundle"
app_resources="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

if [ ! -f "${bundle_dir}/tflite_langid.tflite" ]; then
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/mlkit-ocr.XXXXXX")"
  trap 'rm -rf "$temp_dir"' EXIT

  curl --fail --location --retry 3 --silent --show-error \
    "https://github.com/d-date/google-mlkit-swiftpm/releases/download/${version}/${archive}" \
    --output "${temp_dir}/${archive}"

  actual_checksum="$(shasum -a 256 "${temp_dir}/${archive}" | awk '{ print $1 }')"
  if [ "${actual_checksum}" != "${checksum}" ]; then
    echo "ML Kit OCR resource checksum verification failed." >&2
    exit 1
  fi

  mkdir -p "${temp_dir}/extracted" "${resource_dir}"
  ditto -x -k "${temp_dir}/${archive}" "${temp_dir}/extracted"
  if [ ! -f "${temp_dir}/extracted/LatinOCRResources.bundle/tflite_langid.tflite" ]; then
    echo "ML Kit OCR resource archive does not contain the expected model." >&2
    exit 1
  fi

  rm -rf "${bundle_dir}"
  mv "${temp_dir}/extracted/LatinOCRResources.bundle" "${bundle_dir}"
fi

mkdir -p "${app_resources}"
ditto "${bundle_dir}" "${app_resources}/LatinOCRResources.bundle"
