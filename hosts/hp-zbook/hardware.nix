{ pkgs, ... }:

let
  btrfsOpts = [
    "noatime"
    "compress=zstd:1"
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
in
{
  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {

        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0022" "dmask=0022" ];
          };
        };

        swap = {
          size = "18G";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-L" "Something filesystem" "-f" ];
            subvolumes = {
              "@"           = { mountpoint = "/";           mountOptions = btrfsOpts; };
              "@home"       = { mountpoint = "/home";       mountOptions = btrfsOpts; };
              "@persistent" = { mountpoint = "/persistent"; mountOptions = btrfsOpts; neededForBoot = true; };
              "@opt"        = { mountpoint = "/opt";        mountOptions = btrfsOpts; };
              "@var_log"    = { mountpoint = "/var/log";    mountOptions = btrfsOpts; };
              "@nix"        = { mountpoint = "/nix";        mountOptions = btrfsOpts; neededForBoot = true; };
              "@snapshots"  = { mountpoint = "/.snapshots"; mountOptions = btrfsOpts; };
            };
          };
        };

      };
    };
  };

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "rw" "nosuid" "nodev" "relatime" "size=4G" "mode=1777" ];
  };

  # ── GPU: NVIDIA Quadro T2000 + Intel UHD 630 (Optimus) ─────────────────────

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = false;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId  = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
      nvidia-vaapi-driver
    ];
  };

  nixpkgs.config.allowUnfree = true;
}
