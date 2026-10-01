# Writes a 256-byte EDID for a fake 2360x1640@60 "iPad" monitor to argv[1].
#
# Why hand-built instead of hardware.display.edid.modelines: that generator
# emits a bare EDID 1.3 block with no CTA-861 extension. Without an HDMI
# vendor block, i915 treats the sink as single-link DVI and caps the pixel
# clock at 165 MHz -- and 2360x1640@60 needs 255 MHz, so every mode was
# silently pruned (niri showed the output with "Available modes:" empty).
# Block 1 below adds the HDMI VSDB declaring a 340 MHz TMDS limit.
#
# Check the result with:  edid-decode <file>   (from v4l-utils)
import sys

def checksum(block):
    block.append((-sum(block)) % 256)
    return block

# --- the one timing: `cvt -r 2360 1640 60` -------------------------------
pclk_10khz = 25500                       # 255.00 MHz
hact, hfp, hsw, htot = 2360, 48, 32, 2520
vact, vfp, vsw, vtot = 1640, 3, 10, 1687
hbl, vbl = htot - hact, vtot - vact
hmm, vmm = 227, 158                      # real iPad 10 panel size (264 ppi)

dtd = [
    pclk_10khz & 0xFF, pclk_10khz >> 8,
    hact & 0xFF, hbl & 0xFF, ((hact >> 8) << 4) | (hbl >> 8),
    vact & 0xFF, vbl & 0xFF, ((vact >> 8) << 4) | (vbl >> 8),
    hfp & 0xFF, hsw & 0xFF, ((vfp & 0xF) << 4) | (vsw & 0xF),
    ((hfp >> 8) << 6) | ((hsw >> 8) << 4) | ((vfp >> 4) << 2) | (vsw >> 4),
    hmm & 0xFF, vmm & 0xFF, ((hmm >> 8) << 4) | (vmm >> 8),
    0, 0,
    0x1A,                                # digital separate sync, +hsync -vsync
]

def text_descriptor(tag, text):
    body = text.encode()[:13]
    if len(body) < 13:
        body += b"\n" + b" " * (12 - len(body))
    return [0, 0, 0, tag, 0] + list(body)

# --- block 0: base EDID 1.3 ---------------------------------------------
base = [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00]
base += [0x31, 0xD8]                     # manufacturer "LNX"
base += [0x01, 0x00]                     # product code
base += [0, 0, 0, 0]                     # serial
base += [0, 2026 - 1990]                 # week, year
base += [1, 3]                           # EDID 1.3
base += [0x80]                           # digital input
base += [hmm // 10, vmm // 10]           # size in cm
base += [120]                            # gamma 2.2
base += [0x0E]                           # RGB, sRGB, first DTD is preferred
base += [0xEE, 0x91, 0xA3, 0x54, 0x4C, 0x99, 0x26, 0x0F, 0x50, 0x54]  # sRGB
base += [0x20, 0, 0]                     # 640x480@60 (required by CTA-861)
base += [0x01, 0x01] * 8                 # no standard timings
base += dtd
# range limits: 50-61 Hz V, 30-110 kHz H, 260 MHz max pixel clock
base += [0, 0, 0, 0xFD, 0, 50, 61, 30, 110, 26, 0, 0x0A] + [0x20] * 6
base += text_descriptor(0xFC, "iPad")    # monitor name
base += [0, 0, 0, 0x10, 0] + [0] * 13    # dummy descriptor
base += [1]                              # one extension block follows
checksum(base)

# --- block 1: CTA-861 extension carrying the HDMI vendor block ----------
hdmi_vsdb = [
    (3 << 5) | 7,                        # vendor-specific block, 7 bytes
    0x03, 0x0C, 0x00,                    # HDMI Licensing OUI 00-0C-03
    0x10, 0x00,                          # physical address 1.0.0.0
    0x00,                                # no deep colour etc.
    340 // 5,                            # max TMDS clock, 5 MHz units
]
vcdb = [(7 << 5) | 2, 0x00, 0x4A]       # video capability: RGB range selectable, underscanned
blocks = hdmi_vsdb + vcdb
cta = [0x02, 0x03, 4 + len(blocks), 0x80] + blocks  # 0x80: underscanned
cta += [0] * (127 - len(cta))
checksum(cta)

assert len(base) == 128 and len(cta) == 128
with open(sys.argv[1], "wb") as f:
    f.write(bytes(base + cta))
