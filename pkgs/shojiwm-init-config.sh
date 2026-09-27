#!/bin/sh
set -eu

config_home="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
config_dir="$config_home/shojiwm"

if [ ! -e "$config_dir/src/index.tsx" ]; then
  mkdir -p "$config_dir"
  cp -R "@out@/share/shojiwm/default-config/." "$config_dir/"
  chmod -R u+w "$config_dir"
fi

mkdir -p "$config_dir/node_modules"
rm -f "$config_dir/node_modules/shoji_wm"
ln -s "@out@/lib/shojiwm/packages/shoji_wm" "$config_dir/node_modules/shoji_wm"

cat > "$config_dir/package.json" <<'EOF'
{
  "name": "shojiwm-user-config",
  "private": true,
  "type": "module",
  "dependencies": {
    "shoji_wm": "file:./node_modules/shoji_wm"
  }
}
EOF

cat > "$config_dir/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "jsx": "react-jsx",
    "jsxImportSource": "shoji_wm",
    "strict": true,
    "verbatimModuleSyntax": true,
    "noEmit": true
  }
}
EOF
