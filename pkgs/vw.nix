# vw from its own nix/package.nix, so upstream build changes come along with
# the source. vw generates its Wayland bindings with zwwm's zwayland, so it
# takes zwwm's source too.
{
  lib,
  callPackage,
  pkg-config,
  src,
  zwwmSrc,
  # libvw.a, linked into each program, which then ships as one binary; its
  # libraries come along for the program to link.
  static ? false,
  # Facet, the declarative view language (vw-facetc, facet_compile()).
  withFacet ? false,
  # The C++ examples and the deprecated Lua frontend (the vw executable).
  withExamples ? !static,
  withLua ? !static,
}:
let
  upstream = callPackage "${src}/nix/package.nix" {
    inherit src withFacet;
    zwwm = zwwmSrc;
  };
in
upstream.overrideAttrs (old: {
  pname = "vw" + lib.optionalString static "-static" + lib.optionalString withFacet "-facet";
  # Bitmap images (window thumbnails) used an iterator that the fitted-bitmap
  # cache's push_back invalidates. Drop once vw carries the fix.
  patches = (old.patches or [ ]) ++ [ ./vw-fitted-bitmap-cache.patch ];
  cmakeFlags = old.cmakeFlags ++ [
    (lib.cmakeBool "VW_STATIC" static)
    (lib.cmakeBool "VW_BUILD_EXAMPLES" withExamples)
    (lib.cmakeBool "VW_WITH_LUA" withLua)
  ];
  propagatedBuildInputs = old.propagatedBuildInputs ++ lib.optionals static old.buildInputs;
  propagatedNativeBuildInputs = (old.propagatedNativeBuildInputs or [ ]) ++ lib.optionals static [ pkg-config ];
  passthru = (old.passthru or { }) // { inherit static withFacet withExamples withLua; };
})
