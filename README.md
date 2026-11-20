# runixpkgs

Independently built packages for experimental Wayland compositors. Each package
uses pinned upstream **source code**, its own derivation in `pkgs/`, and the
same nixpkgs input; upstream flake package outputs are not used.

| Package | Upstream | Build options |
| --- | --- | --- |
| `zwwm` | [zwwmWM/zwwm](https://github.com/zwwmWM/zwwm) | `xwaylandSupport ? true` (CMake `XWAYLAND_ENABLE`) |
| `vw` | [binarylinuxx/vw](https://github.com/binarylinuxx/vw) | `static ? false` (`vw-static`: libvw.a for one-binary shells), `withFacet ? false`, `withExamples ? !static`, `withLua ? !static` |
| `shojiwm` | [bea4dev/ShojiWM](https://github.com/bea4dev/ShojiWM) | `heapDebug ? false` (Cargo `shoji_wm/heap-debug`), `xwaylandSupport ? true` (runtime Xwayland), `satelliteSupport ? true` (runtime xwayland-satellite) |
| `driftwm` | [malbiruk/driftwm](https://github.com/malbiruk/driftwm) | `tracySupport ? false`, `tracyOnDemand ? false`, `tracyAllocations ? false` (Cargo features) |

For example:

```sh
nix build .#zwwm
nix build .#vw          # or .#vw-static, the library shells link
nix build .#shojiwm
nix build .#driftwm
```

Runix includes this overlay by default. Select packages from its system package
set in your host configuration:

```nix
# In your host flake outputs = { runix, ... }:
runix.lib.runixSystem {
  system = "x86_64-linux";
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

For a standalone nixpkgs instance, use `runixpkgs.overlays.default` (also
re-exported by Runix as `runix.overlays.default`).

Override an individual build without changing the others:

```nix
pkgs.zwwm.override { xwaylandSupport = false; }
pkgs.shojiwm.override { heapDebug = true; satelliteSupport = false; }
pkgs.driftwm.override { tracySupport = true; tracyOnDemand = true; }
```

ShojiWM's upstream source unconditionally enables Smithay's Xwayland build
feature; `xwaylandSupport` only controls the installed runtime dependency.

GitHub Actions builds every package independently on `x86_64-linux` and
`aarch64-linux` (native ARM runners). With a
write token, commits to the repository's default branch publish the results to
[`runix-community.cachix.org`](https://runix-community.cachix.org); pull
requests use that cache read-only. Without the token, CI still builds and
uses Cachix read-only. Add a repository Actions secret named
`CACHIX_AUTH_TOKEN` with a Cachix write token to enable publishing.
