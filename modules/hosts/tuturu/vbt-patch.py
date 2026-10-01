# Lifts the 165 MHz HDMI cap from this laptop's Intel VBT (Video BIOS
# Table) so the fake iPad monitor's 2360x1640@60 (255 MHz) mode survives.
#
#   in:  argv[1]  the VBT exactly as the firmware ships it, dumped with
#                 sudo cat /sys/kernel/debug/dri/1/i915_vbt > vbt-original.bin
#   out: argv[2]  the same VBT with ONE field changed
#
# The field: in the child-device entry for the HDMI port (handle 0x0004
# "EFP1", type 0x60d2), byte 7 packs two values --
#   bits 5-7  hdmi_max_data_rate   0 = platform max, 2 = 165 MHz  <- we clear this
#   bits 0-4  hdmi_level_shifter   left untouched
# Verify with: intel_vbt_decode --file <out> --devid 0xa7a9
# ("HDMI max data rate" for EFP1 should read <platform max>).
#
# Why it's safe here: the cap reflects what the physical HDMI wiring on the
# board can carry. Nothing is ever plugged into this port -- it only exists
# to host the fake monitor that Sunshine captures in software.
import struct, sys

data = bytearray(open(sys.argv[1], "rb").read())
assert data[:4] == b"$VBT", "not a VBT"

efp1 = bytes([0x04, 0x00, 0xD2, 0x60])   # handle 0x0004, device type 0x60d2
assert data.count(efp1) == 1, "EFP1 child device not found exactly once"
field = data.find(efp1) + 7

old = data[field]
assert old >> 5 == 2, f"expected the 165 MHz cap (2), found {old >> 5}"
data[field] = old & 0x1F                 # data rate -> 0 (platform max)

# Keep the header checksum byte (offset 26) consistent: the byte sum over
# vbt_size must not change.
vbt_size = struct.unpack_from("<H", data, 24)[0]
data[26] = (data[26] + (old - data[field])) % 256

open(sys.argv[2], "wb").write(data)
