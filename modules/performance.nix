{ ... }:
{
  boot.kernel.sysctl = {
    "vm.swappiness"                  = 180;
    "vm.page-cluster"                = 0;
    "vm.dirty_background_bytes"      = 67108864;   # 64M
    "vm.dirty_bytes"                 = 268435456;  # 256M
    "vm.dirty_expire_centisecs"      = 3000;
    "vm.dirty_writeback_centisecs"   = 1500;
  };

  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';
}
