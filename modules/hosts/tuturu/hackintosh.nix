# =============================================================================
# hackintosh  --  tooling for the macOS Tahoe project (repo: thatDelta/tuturu-hackintosh)
# =============================================================================
#
# WHAT THIS ADDS
#   1. A reverse-engineering / debugging toolbox (ghidra, rizin, ipsw, lldb,
#      intel-gpu-tools, acpica, qemu ...) for working on Apple's GPU driver
#      and the OpenCore EFI from Linux.
#   2. hw-capture: a fixed, READ-ONLY root script that dumps hardware ground
#      truth (panel DPCD, i915 state, GPU registers, ACPI tables, CFG lock,
#      DVMT, IOMMU groups) into /var/lib/hw-capture/<timestamp>/.
#      Trigger it without a password:   touch /var/lib/hw-capture/request
#      (Claude's shell cannot sudo -- no_new_privs -- so this is how it reads
#      root-only things. The request file's contents are ignored.)
#   3. VM support for a macOS QEMU/KVM guest: IOMMU on, KVM MSR quirk,
#      unlimited memlock for VFIO, and vfio-wifi.service to lend the Wi-Fi
#      card to the VM (polkit lets you start/stop it without a password).
#      WHILE IT RUNS THE LAPTOP HAS NO WI-FI -- use phone USB tethering.
#   4. Read-only APFS support (linux-apfs-rw) to read macOS logs from Linux.
#   5. Raw access for your user to the Crucial BX500 SATA SSD, so the VM can
#      install macOS onto it -- ONLY once the bwoah mount is gone (see below).
#
# SAFETY
#   The raw-disk rule is switched off automatically while /mnt/bwoah is still
#   configured, so the VM can never write to a disk Linux has mounted.
#   To enable it: finish moving files off bwoah, remove tuturuBwoah (and the
#   jellyfin library paths on it), rebuild.
#
# TO DISCARD: delete this file and its line in configuration.nix.
# =============================================================================
{ ... }:
{
  flake.nixosModules.tuturuHackintosh =
    { pkgs, lib, config, ... }:
    let
      user = config.my.username;
      sataSerial = "2418E8AC0703"; # CT1000BX500SSD1, /dev/disk/by-id/ata-CT1000BX500SSD1_2418E8AC0703
      bwoahStillMounted = config.fileSystems ? "/mnt/bwoah";

      capture = pkgs.writeShellApplication {
        name = "hw-capture";
        runtimeInputs = with pkgs; [
          coreutils util-linux pciutils intel-gpu-tools acpica-tools
          msr-tools kmod dmidecode efibootmgr gptfdisk findutils gnugrep
        ];
        text = ''
          set +e   # best effort: one failing probe must not stop the rest
          out=/var/lib/hw-capture/$(date +%Y%m%d-%H%M%S)
          mkdir -p "$out"
          cd "$out"
          exec 2>"$out/errors.log"

          uname -a > uname.txt
          cat /proc/cmdline > cmdline.txt
          dmesg > dmesg.txt
          lspci -vvv -nn > lspci-vvv.txt
          for g in /sys/kernel/iommu_groups/*; do
            echo "group ''${g##*/}:" "$g"/devices/*
          done > iommu-groups.txt

          # --- panel DisplayPort AUX (DPCD): reads only ---------------------
          aux=/dev/drm_dp_aux0
          dpcd() { dd if="$aux" bs=1 skip=$(( $1 )) count=$(( $2 )) 2>/dev/null | od -An -tx1 -v; }
          {
            echo "# $(cat /sys/class/drm_dp_aux_dev/drm_dp_aux0/name)"
            for r in 0x000:0x20 0x100:0x20 0x200:0x08 0x2200:0x10 0x700:0x08; do
              echo "== DPCD ''${r%%:*} (+''${r#*:})"; dpcd "''${r%%:*}" "''${r#*:}"
            done
          } > dpcd.txt

          # --- i915 state ------------------------------------------------------
          mountpoint -q /sys/kernel/debug || mount -t debugfs none /sys/kernel/debug
          for d in /sys/kernel/debug/dri/*/; do
            [ -e "$d/i915_display_info" ] || continue
            mkdir -p i915
            for f in i915_display_info i915_cdclk_info i915_frequency_info i915_edp_psr_status \
                     i915_power_domain_info i915_dmc_info i915_gpu_info; do
              [ -e "$d/$f" ] && cat "$d/$f" > "i915/$f.txt"
            done
            [ -e "$d/i915_vbt" ] && cat "$d/i915_vbt" > i915/i915_vbt.bin
            [ -d "$d/eDP-1" ] && for f in "$d"/eDP-1/*; do cat "$f" > "i915/eDP-1_$(basename "$f").txt"; done
          done
          intel_reg dump > intel_reg_dump.txt

          # --- firmware facts ----------------------------------------------------
          mkdir -p acpi && (cd acpi && acpidump -b)
          modprobe msr
          echo "MSR 0xE2 (bit 15 = CFG lock): $(rdmsr -a 0xe2 | tr '\n' ' ')" > msr.txt
          {
            echo "IGD GGC (00:02.0 0x50): $(setpci -s 00:02.0 0x50.w)"
            echo "Host GGC (00:00.0 0x50): $(setpci -s 00:00.0 0x50.w)"
            echo "IGD BDSM (00:02.0 0x5c): $(setpci -s 00:02.0 0x5c.l)"
          } > dvmt.txt
          dmidecode > dmidecode.txt
          efibootmgr -v > efibootmgr.txt
          for d in /dev/nvme0n1 /dev/sda; do [ -b "$d" ] && sgdisk -p "$d"; done > partitions.txt

          chown -R ${user}:users "$out"
          echo "$out"
        '';
      };
    in
    {
      # --- 1. toolbox ---------------------------------------------------------
      environment.systemPackages = with pkgs; [
        # reverse engineering
        ghidra rizin radare2 ipsw lldb gdb
        # Apple payloads
        xar pbzx p7zip dmg2img libplist apfsprogs apfs-fuse
        # firmware, display, GPU
        intel-gpu-tools edid-decode acpica-tools uefitool efibootmgr gptfdisk mtools
        # VM
        qemu OVMF.fd socat
        capture
      ];

      # --- 2. capture service ---------------------------------------------------
      systemd.tmpfiles.rules = [
        "d /var/lib/hw-capture 0755 ${user} users -"
        "f /var/lib/hw-capture/request 0644 ${user} users -"
      ];
      systemd.services.hw-capture = {
        description = "Read-only hardware ground-truth capture for the hackintosh project";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe capture;
        };
      };
      systemd.paths.hw-capture = {
        wantedBy = [ "multi-user.target" ];
        pathConfig.PathChanged = "/var/lib/hw-capture/request";
      };
      boot.kernel.sysctl."kernel.dmesg_restrict" = 0;

      # --- 3. VM support --------------------------------------------------------
      boot.kernelParams = [ "intel_iommu=on" "iommu=pt" ];
      boot.kernelModules = [ "vfio-pci" ];
      boot.extraModprobeConfig = "options kvm ignore_msrs=1 report_ignored_msrs=0";
      users.users.${user}.extraGroups = [ "kvm" ];
      systemd.user.settings.Manager.DefaultLimitMEMLOCK = "infinity";
      security.pam.loginLimits = [
        { domain = user; type = "-"; item = "memlock"; value = "unlimited"; }
      ];
      services.udev.extraRules = ''
        SUBSYSTEM=="vfio", GROUP="kvm", MODE="0660"
      '' + lib.optionalString (!bwoahStillMounted) ''
        KERNEL=="sd?", ENV{ID_SERIAL_SHORT}=="${sataSerial}", OWNER="${user}", MODE="0660"
      '';

      # Lend the RTL8852BE (02:00.0) to the VM. stop = give it back to Linux.
      systemd.services.vfio-wifi = {
        description = "Detach the Wi-Fi card from Linux for the macOS VM";
        serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
        script = ''
          dev=/sys/bus/pci/devices/0000:02:00.0
          echo vfio-pci > $dev/driver_override
          [ -e $dev/driver ] && echo 0000:02:00.0 > $dev/driver/unbind
          echo 0000:02:00.0 > /sys/bus/pci/drivers_probe
        '';
        preStop = ''
          dev=/sys/bus/pci/devices/0000:02:00.0
          echo > $dev/driver_override
          [ -e $dev/driver ] && echo 0000:02:00.0 > $dev/driver/unbind
          echo 0000:02:00.0 > /sys/bus/pci/drivers_probe
        '';
      };
      # --- 6. S3 sleep test (docs/sleep.md step 1) --------------------------------
      # Dell ships Name (SS3, Zero) so only s2idle is offered. This initrd ACPI upgrade loads the same DSDT with
      # SS3 = One (OEM rev 2 -> 3; built from hw/capture-20261119/acpi/dsdt.dat by the hackintosh repo). Because the
      # FADT has LOW_POWER_S0, the kernel keeps s2idle as default; "deep" just becomes available.
      # s3-test.service: one S3 cycle, logged to /var/lib/hw-capture/s3-test.log, then back to s2idle.
      # RESULT 2026-11-21: S3 entered ("PM: suspend entry (deep)") but never resumed; power-button hard reset needed.
      # Firmware S3 resume is dead, so the override is OFF (stock tables). Kept for reference; set to true to retest.
      boot.initrd.prepend = lib.optionals false [ "${pkgs.runCommand "acpi-dsdt-ss3.cpio" { nativeBuildInputs = [ pkgs.cpio ]; } ''
        mkdir -p kernel/firmware/acpi && cp ${./acpi/dsdt-ss3.aml} kernel/firmware/acpi/dsdt.aml
        find kernel | cpio -H newc --create > $out
      ''}" ];
      systemd.services.s3-test = {
        description = "One S3 (deep) suspend cycle with logging";
        serviceConfig.Type = "oneshot";
        path = [ pkgs.util-linux pkgs.systemd pkgs.gnugrep pkgs.coreutils ];
        script = ''
          set +e   # logging must never stop the test
          log=/var/lib/hw-capture/s3-test.log
          { echo "== $(date -Is) mem_sleep: $(cat /sys/power/mem_sleep)"
            cat /sys/class/power_supply/BAT0/charge_now
          } >> $log
          echo deep > /sys/power/mem_sleep
          echo 0 > /sys/power/pm_test 2>/dev/null || true
          echo mem > /sys/power/state || echo "suspend failed rc=$?" >> $log
          { echo "== resumed $(date -Is)"; cat /sys/class/power_supply/BAT0/charge_now
            cat /sys/kernel/debug/suspend_stats 2>/dev/null || cat /sys/power/suspend_stats/* 2>/dev/null
            dmesg | grep -iE "ACPI: PM|S3|PM: suspend|PM: resume|resume|wake" | tail -40
          } >> $log
          echo s2idle > /sys/power/mem_sleep
          chmod 644 $log
        '';
      };

      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "${user}" &&
              /^(vfio-wifi|hw-capture|s3-test)\.service$/.test(action.lookup("unit"))) {
            return polkit.Result.YES;
          }
        });
      '';

      # --- 5. boot menu entry for macOS -----------------------------------------
      # OpenCore lives in \EFI\OC on this ESP (copied from the hackintosh repo's build, not managed by Nix).
      # NixOS stays the default; NixOS is never booted THROUGH OpenCore.
      boot.loader.systemd-boot.extraEntries."opencore.conf" = ''
        title macOS Tahoe (OpenCore)
        efi /EFI/OC/OpenCore.efi
        sort-key z_opencore
      '';

      # --- 4. read macOS volumes (read-only) ------------------------------------
      boot.extraModulePackages = [ config.boot.kernelPackages.apfs ];
    };
}
