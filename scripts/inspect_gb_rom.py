#!/usr/bin/env python3
"""Inspect Game Boy / Game Boy Color ROM metadata without executing the ROM."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


MIN_HEADER_SIZE = 0x150

CARTRIDGE_TYPES = {
    0x00: "ROM ONLY",
    0x01: "MBC1",
    0x02: "MBC1+RAM",
    0x03: "MBC1+RAM+BATTERY",
    0x05: "MBC2",
    0x06: "MBC2+BATTERY",
    0x08: "ROM+RAM",
    0x09: "ROM+RAM+BATTERY",
    0x0F: "MBC3+TIMER+BATTERY",
    0x10: "MBC3+TIMER+RAM+BATTERY",
    0x11: "MBC3",
    0x12: "MBC3+RAM",
    0x13: "MBC3+RAM+BATTERY",
    0x19: "MBC5",
    0x1A: "MBC5+RAM",
    0x1B: "MBC5+RAM+BATTERY",
    0x1C: "MBC5+RUMBLE",
    0x1D: "MBC5+RUMBLE+RAM",
    0x1E: "MBC5+RUMBLE+RAM+BATTERY",
    0x20: "MBC6",
    0x22: "MBC7+SENSOR+RUMBLE+RAM+BATTERY",
    0xFC: "POCKET CAMERA",
    0xFD: "BANDAI TAMA5",
    0xFE: "HuC3",
    0xFF: "HuC1+RAM+BATTERY",
}

ROM_SIZE_BYTES = {
    0x00: 32 * 1024,
    0x01: 64 * 1024,
    0x02: 128 * 1024,
    0x03: 256 * 1024,
    0x04: 512 * 1024,
    0x05: 1024 * 1024,
    0x06: 2 * 1024 * 1024,
    0x07: 4 * 1024 * 1024,
    0x08: 8 * 1024 * 1024,
    0x52: 1152 * 1024,
    0x53: 1280 * 1024,
    0x54: 1536 * 1024,
}

RAM_SIZE_BYTES = {
    0x00: 0,
    0x01: 2 * 1024,
    0x02: 8 * 1024,
    0x03: 32 * 1024,
    0x04: 128 * 1024,
    0x05: 64 * 1024,
}


def _hex_byte(value: int) -> str:
    return f"0x{value:02X}"


def _cgb_mode(flag: int) -> str:
    if flag == 0xC0:
        return "cgb_only"
    if flag & 0x80:
        return "cgb_compatible"
    return "dmg"


def _header_checksum(data: bytes) -> int:
    checksum = 0
    for value in data[0x134:0x14D]:
        checksum = (checksum - value - 1) & 0xFF
    return checksum


def inspect_rom(path: str | Path, expected_sha256: str | None = None) -> dict[str, Any]:
    rom_path = Path(path)
    data = rom_path.read_bytes()
    if len(data) < MIN_HEADER_SIZE:
        raise ValueError(
            f"{rom_path} is too small to contain a valid GB/GBC header "
            f"({len(data)} bytes; need at least {MIN_HEADER_SIZE})"
        )

    sha256 = hashlib.sha256(data).hexdigest()
    if expected_sha256 is not None and sha256.lower() != expected_sha256.lower():
        raise ValueError(
            f"SHA-256 mismatch for {rom_path}: expected {expected_sha256.lower()}, got {sha256}"
        )

    title_bytes = data[0x134:0x143]
    title = title_bytes.split(b"\0", 1)[0].rstrip(b" ").decode("ascii", errors="replace")

    cgb_flag = data[0x143]
    sgb_flag = data[0x146]
    cartridge_type = data[0x147]
    rom_size_code = data[0x148]
    ram_size_code = data[0x149]
    stored_header_checksum = data[0x14D]
    computed_header_checksum = _header_checksum(data)

    return {
        "rom_path": str(rom_path),
        "sha256": sha256,
        "file_size_bytes": len(data),
        "title": title,
        "platform": "GBC" if cgb_flag & 0x80 else "GB",
        "cgb_mode": _cgb_mode(cgb_flag),
        "cgb_flag": _hex_byte(cgb_flag),
        "sgb_flag": _hex_byte(sgb_flag),
        "cartridge_type": _hex_byte(cartridge_type),
        "cartridge_type_name": CARTRIDGE_TYPES.get(cartridge_type, "UNKNOWN"),
        "rom_size_code": _hex_byte(rom_size_code),
        "rom_size_bytes": ROM_SIZE_BYTES.get(rom_size_code),
        "ram_size_code": _hex_byte(ram_size_code),
        "ram_size_bytes": RAM_SIZE_BYTES.get(ram_size_code),
        "header_checksum": _hex_byte(stored_header_checksum),
        "computed_header_checksum": _hex_byte(computed_header_checksum),
        "header_checksum_valid": stored_header_checksum == computed_header_checksum,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Inspect GB/GBC ROM header metadata and SHA-256 without executing it."
    )
    parser.add_argument("rom_path", help="Path to a .gb or .gbc ROM")
    parser.add_argument(
        "--expect-sha256",
        help="Fail if the ROM SHA-256 does not match this digest",
    )
    parser.add_argument(
        "--compact",
        action="store_true",
        help="Emit one-line JSON instead of pretty-printed JSON",
    )
    args = parser.parse_args()

    try:
        metadata = inspect_rom(args.rom_path, args.expect_sha256)
    except (OSError, ValueError) as exc:
        parser.error(str(exc))

    print(
        json.dumps(
            metadata,
            ensure_ascii=False,
            indent=None if args.compact else 2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
