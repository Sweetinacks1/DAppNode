#!/bin/bash

download_iso() {
    local iso_path=$1
    local iso_name=$2
    local iso_url=$3

    echo "[INFO] Downloading ISO image: ${iso_name}..."
    if [ ! -f "${iso_path}" ]; then
        wget "${iso_url}" -O "${iso_path}"
    fi
    echo "[INFO] Download complete!"
}

verify_download() {
    local iso_path=$1
    local expected_shasum=$2

    echo "[INFO] Verifying download..."
    local calculated_shasum=$(shasum -a 256 "${iso_path}" | awk '{ print $1 }')
    if [ "${calculated_shasum}" != "${expected_shasum}" ]; then
        echo "[ERROR] Wrong shasum"
        exit 1
    fi
    echo "[INFO] Verification complete!"
}

clean_old_files() {
    local iso_extraction_dir=$1
    local base_iso_prefix=$2

    echo "[INFO] Cleaning old files..."
    rm -rf "${iso_extraction_dir}º"
    rm -rf "${base_iso_prefix}*"
}

extract_iso() {
    local iso_path=$1
    local extraction_target_dir=$2

    echo "[INFO] Extracting the ISO..."
    osirrox -indev "${iso_path}" -extract / "${extraction_target_dir}"
}

# Using a 512-byte block size to ensure the entire Master Boot Record (MBR) is captured.
# The MBR contains boot code, the partition table, and a boot signature, all essential for creating bootable media.
# This ensures that the new ISO being created is bootable under different system setups
prepare_boot_process() {
    local iso_path=$1
    local mbr_output_path=$2
    local block_size=512

    echo "[INFO] Obtaining the MBR for hybrid ISO..."
    dd if="${iso_path}" bs=${block_size} count=1 of="${mbr_output_path}"
}

handle_checksums() {
    echo "Fix md5 sum..."
    # shellcheck disable=SC2046
    md5sum $(find ! -name "md5sum.txt" ! -path "./isolinux/*" -type f) >md5sum.txt
}
