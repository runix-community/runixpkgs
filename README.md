# runixpkgs

Independently built packages for experimental Wayland compositors. Each package
uses pinned upstream **source code**, its own derivation in `pkgs/`, and the
same nixpkgs input; upstream flake package outputs are not used.

| Package | Upstream | Build options |
| --- | --- | --- |
| `zwwm` | [binarylinuxx/zwwm](https://github.com/binarylinuxx/zwwm) | `xwaylandSupport ? true` (CMake `XWAYLAND_ENABLE`) |
| `shojiwm` | [bea4dev/ShojiWM](https://github.com/bea4dev/ShojiWM) | `heapDebug ? false` (Cargo `shoji_wm/heap-debug`), `xwaylandSupport ? true` (runtime Xwayland), `satelliteSupport ? true` (runtime xwayland-satellite) |
| `driftwm` | [malbiruk/driftwm](https://github.com/malbiruk/driftwm) | `tracySupport ? false`, `tracyOnDemand ? false`, `tracyAllocations ? false` (Cargo features) |

For example:

```sh
nix build .#zwwm
nix build .#shojiwm
nix build .#driftwm
```

Use the overlay and pass its packages to Runix system configuration:

```nix
# In your host flake outputs = { runix, runixpkgs, nixpkgs, ... }:
let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ runixpkgs.overlays.default ];
  };
in
runix.lib.runixSystem {
  inherit system pkgs;
  modules = [
    ({ pkgs, ... }: {
      runix.packages = [
        pkgs.zwwm
        pkgs.shojiwm
        pkgs.driftwm
      ];
    })
  ];
}
```

Override an individual build without changing the others:

```nix
pkgs.zwwm.override { xwaylandSupport = false; }
pkgs.shojiwm.override { heapDebug = true; satelliteSupport = false; }
pkgs.driftwm.override { tracySupport = true; tracyOnDemand = true; }
```

ShojiWM's upstream source unconditionally enables Smithay's Xwayland build
feature; `xwaylandSupport` only controls the installed runtime dependency.

GitHub Actions builds each package independently on `x86_64-linux`. With a
write token, commits to the repository's default branch publish the results to
[`runix-community.cachix.org`](https://runix-community.cachix.org); pull
requests use that cache read-only. Without the token, CI still builds and
uses Cachix read-only. Add a repository Actions secret named
`CACHIX_AUTH_TOKEN` with a Cachix write token to enable publishing.
