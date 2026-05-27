{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.kdePackages.kirigami
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Auto-power the adapter when it (re)appears, e.g. after resume.
  hardware.bluetooth.settings.Policy.AutoEnable = true;

  # The BT controller loses its powered state across suspend and bluez doesn't
  # reliably bring it back, so explicitly re-enable it on resume. Runs as root
  # via the systemd sleep hook.
  powerManagement.resumeCommands = ''
    ${pkgs.util-linux}/bin/rfkill unblock bluetooth || true
    ${pkgs.coreutils}/bin/sleep 1
    ${pkgs.bluez}/bin/bluetoothctl power on || true
  '';

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
}
