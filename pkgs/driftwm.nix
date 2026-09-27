{
  lib,
  rustPlatform,
  src,
  pkg-config,
  patchelf,
  wayland,
  wayland-protocols,
  seatd,
  libdisplay-info_0_3,
  libinput,
  libgbm,
  libxkbcommon,
  libdrm,
  systemd,
  libglvnd,
  libx11,
  libxcursor,
  libxrandr,
  libxi,
  libxcb,
  pixman,
  tracySupport ? false,
  tracyOnDemand ? false,
  tracyAllocations ? false,
}:
assert !tracyOnDemand || tracySupport;
assert !tracyAllocations || tracySupport;
let
  libraries = [
    wayland wayland-protocols seatd libdisplay-info_0_3 libinput libgbm
    libxkbcommon libdrm systemd libglvnd libx11 libxcursor libxrandr
    libxi libxcb pixman
  ];
in
rustPlatform.buildRustPackage {
  pname = "driftwm";
  version = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package.version;
  inherit src;
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };
  cargoBuildFlags = lib.optionals tracySupport [ "--features" "profile-with-tracy" ]
    ++ lib.optionals tracyOnDemand [ "--features" "profile-with-tracy-ondemand" ]
    ++ lib.optionals tracyAllocations [ "--features" "profile-with-tracy-allocations" ];
  nativeBuildInputs = [ pkg-config patchelf ];
  buildInputs = libraries;
  doCheck = false;

  postInstall = ''
    install -Dm755 resources/driftwm-session "$out/bin/driftwm-session"
    install -Dm644 resources/driftwm.desktop "$out/share/wayland-sessions/driftwm.desktop"
    install -Dm644 resources/driftwm-portals.conf "$out/share/xdg-desktop-portal/driftwm-portals.conf"
    install -Dm644 config.reference.toml "$out/etc/driftwm/config.reference.toml"
    for file in extras/wallpapers/*.glsl; do
      install -Dm644 "$file" "$out/share/driftwm/wallpapers/$(basename "$file")"
    done
    substituteInPlace "$out/share/wayland-sessions/driftwm.desktop" \
      --replace-fail 'Exec=driftwm-session' "Exec=$out/bin/driftwm-session"
    substituteInPlace "$out/bin/driftwm-session" \
      --replace-fail 'exec driftwm --backend udev' "exec $out/bin/driftwm --backend udev"
  '';
  postFixup = ''
    patchelf --add-rpath "${lib.makeLibraryPath libraries}" "$out/bin/driftwm"
  '';
  passthru = {
    inherit tracySupport tracyOnDemand tracyAllocations;
    providedSessions = [ "driftwm" ];
  };
  meta = {
    description = "Trackpad-first infinite canvas Wayland compositor";
    homepage = "https://github.com/malbiruk/driftwm";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "driftwm-session";
  };
}
