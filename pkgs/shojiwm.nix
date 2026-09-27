{
  lib,
  stdenv,
  rustPlatform,
  src,
  fetchurl,
  clang,
  llvmPackages,
  makeWrapper,
  pkg-config,
  bash,
  wayland,
  wayland-protocols,
  libxkbcommon,
  systemd,
  libinput,
  mesa,
  libglvnd,
  libgbm,
  pixman,
  seatd,
  pipewire,
  libdrm,
  dbus,
  xwayland,
  xwayland-satellite,
  xwaylandSupport ? true,
  satelliteSupport ? true,
  heapDebug ? false,
}:
let
  system = stdenv.hostPlatform.system;
  target = {
    x86_64-linux = "x86_64-unknown-linux-gnu";
    aarch64-linux = "aarch64-unknown-linux-gnu";
  }.${system};
  archiveHash = {
    x86_64-linux = "sha256-xHmofo8wTNg88/TuC2pX2OHDRYtHncoSvSBnTV65o+0=";
    aarch64-linux = "sha256-24q6wX8RTRX1tMGqgcz9/wN3Y+hWxM2SEuVrYhECyS8=";
  }.${system};
  rustyV8Archive = fetchurl {
    url = "https://github.com/denoland/rusty_v8/releases/download/v142.2.0/librusty_v8_release_${target}.a.gz";
    hash = archiveHash;
  };
  libraries = [
    wayland libxkbcommon systemd libinput mesa libglvnd libgbm pixman
    seatd pipewire libdrm
  ];
  runtimePath = [ dbus ]
    ++ lib.optional xwaylandSupport xwayland
    ++ lib.optional satelliteSupport xwayland-satellite;
in
rustPlatform.buildRustPackage {
  pname = "shojiwm";
  version = "0.1.0";
  inherit src;
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "smithay-0.7.0" = "sha256-l2IXXk5kaiUzXPc8JFCW7POxvHRDfiFNE1nq5OaT6QQ=";
      "smithay-drm-extras-0.1.0" = "sha256-l2IXXk5kaiUzXPc8JFCW7POxvHRDfiFNE1nq5OaT6QQ=";
      "rustyscript-0.12.3" = "sha256-04yZws8aY6NpyQc0F6fg7CAwYYXer7r+eFABwafP+kU=";
    };
  };
  cargoBuildFlags = [ "-p" "shoji_wm" "-p" "xdg-desktop-portal-shojiwm" ]
    ++ lib.optionals heapDebug [ "--features" "shoji_wm/heap-debug" ];
  nativeBuildInputs = [ clang makeWrapper pkg-config ];
  buildInputs = libraries ++ [ wayland-protocols ];
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
  RUSTY_V8_ARCHIVE = rustyV8Archive;
  doCheck = false;

  postInstall = ''
    shoji_bin="$(find target -path '*/release/shoji_wm' -type f -perm -0100 -print -quit)"
    portal_bin="$(find target -path '*/release/xdg-desktop-portal-shojiwm' -type f -perm -0100 -print -quit)"
    test -n "$shoji_bin" && test -n "$portal_bin"
    install -Dm755 "$shoji_bin" "$out/bin/.shoji_wm-unwrapped"
    install -Dm755 "$portal_bin" "$out/bin/xdg-desktop-portal-shojiwm"
    mkdir -p "$out/lib/shojiwm/packages" "$out/lib/shojiwm/tools" "$out/share/shojiwm/default-config"
    cp -R packages/shoji_wm "$out/lib/shojiwm/packages/"
    cp tools/decoration-runtime.ts "$out/lib/shojiwm/tools/"
    cp -R packages/config/. "$out/share/shojiwm/default-config/"
    install -Dm755 ${./shojiwm-init-config.sh} "$out/bin/shojiwm-init-config"
    substituteInPlace "$out/bin/shojiwm-init-config" \
      --replace-fail '#!/bin/sh' '#!${bash}/bin/sh' \
      --replace-fail '@out@' "$out"
    makeWrapper "$out/bin/.shoji_wm-unwrapped" "$out/bin/shoji_wm" \
      --set-default SHOJI_RUNTIME_DIR "$out/lib/shojiwm" \
      --set-default SHOJI_DECORATION_RUNTIME "$out/lib/shojiwm/tools/decoration-runtime.ts" \
      --prefix PATH : "${lib.makeBinPath runtimePath}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libraries}" \
      --suffix GBM_BACKENDS_PATH : "${mesa}/lib/gbm" \
      --suffix LIBGL_DRIVERS_PATH : "${mesa}/lib/dri" \
      --suffix __EGL_VENDOR_LIBRARY_DIRS : "${mesa}/share/glvnd/egl_vendor.d" \
      ${lib.optionalString satelliteSupport ''--set-default SHOJI_XWAYLAND_SATELLITE_PATH "${xwayland-satellite}/bin/xwayland-satellite"''}
    wrapProgram "$out/bin/xdg-desktop-portal-shojiwm" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libraries}"
    mkdir -p "$out/share/wayland-sessions" "$out/share/xdg-desktop-portal/portals" "$out/share/dbus-1/services"
    cat > "$out/share/wayland-sessions/shojiwm.desktop" <<EOF
    [Desktop Entry]
    Name=ShojiWM
    Exec=$out/bin/shoji_wm --tty
    Type=Application
    DesktopNames=ShojiWM
    EOF
    cat > "$out/share/xdg-desktop-portal/portals/shojiwm.portal" <<EOF
    [portal]
    DBusName=org.freedesktop.impl.portal.desktop.shojiwm
    Interfaces=org.freedesktop.impl.portal.ScreenCast
    UseIn=ShojiWM
    EOF
    cat > "$out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.shojiwm.service" <<EOF
    [D-BUS Service]
    Name=org.freedesktop.impl.portal.desktop.shojiwm
    Exec=$out/bin/xdg-desktop-portal-shojiwm
    EOF
  '';

  passthru = {
    inherit xwaylandSupport satelliteSupport heapDebug;
    providedSessions = [ "shojiwm" ];
  };
  meta = {
    description = "TypeScript-configured Wayland compositor";
    homepage = "https://github.com/bea4dev/ShojiWM";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "shoji_wm";
  };
}
