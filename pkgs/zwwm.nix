# zwwm from its own nix/package.nix, so upstream build changes come along
# with the source, adjusted for Runix: no systemd, so udev is libudev-zero.
{
  callPackage,
  clangStdenv,
  libinput,
  libudev-zero,
  qt6,
  src,
}:
let
  udev = libudev-zero;
  libinputWithoutSystemd = libinput.override {
    inherit udev;
    wacomSupport = false;
  };
  upstream = callPackage "${src}/nix/package.nix" {
    self = src;
    stdenv = clangStdenv;
    wrapQtAppsHook = qt6.wrapQtAppsHook;
    libinput = libinputWithoutSystemd;
  };
in
upstream.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [ udev ];
  # libudev-zero needs libinput to have its own udev context: shared with
  # zwwm's DRM monitor, input devices are never seen. --replace-fail stops
  # the build if upstream rewrites this line, rather than losing input.
  postPatch = (old.postPatch or "") + ''
    substituteInPlace zwwm/src/runtime_backend.cpp --replace-fail \
      'libinput_udev_create_context(&kLibinputInterface, this, udev_)' \
      'libinput_udev_create_context(&kLibinputInterface, this, udev_new())'
  '';
})
