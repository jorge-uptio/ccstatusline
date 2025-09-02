{
  description = "ccstatusline - A customizable status line formatter for Claude Code CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Simple wrapper that installs via npm/npx for best compatibility
        ccstatusline = pkgs.writeShellScriptBin "ccstatusline" ''
          # Use npx to run the latest version, ensuring all dependencies are available
          if command -v npx >/dev/null 2>&1; then
            exec ${pkgs.nodejs}/bin/npx ccstatusline@latest "$@"
          elif command -v bun >/dev/null 2>&1; then
            exec ${pkgs.bun}/bin/bunx ccstatusline@latest "$@"  
          else
            echo "Error: Neither npm nor bun found. Please install Node.js or Bun." >&2
            exit 1
          fi
        '';

        # Development version that builds from source
        ccstatusline-dev = pkgs.stdenv.mkDerivation rec {
          pname = "ccstatusline-dev";
          version = "1.2.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            bun
            nodejs
            nodePackages.npm
          ];

          dontConfigure = true;

          buildPhase = ''
            export HOME=$TMPDIR
            export npm_config_cache=$TMPDIR/.npm
            export BUN_INSTALL_CACHE_DIR=$TMPDIR/.bun-cache
            
            # Install dependencies if available, but don't fail if network issues
            if bun install --frozen-lockfile 2>/dev/null; then
              echo "Dependencies installed successfully"
              
              # Apply patches if they exist
              if [ -f patches/*.patch ]; then
                ${pkgs.nodePackages.patch-package}/bin/patch-package 2>/dev/null || true
              fi
              
              # Build the project
              bun run build
            else
              echo "Could not install dependencies, creating minimal build"
              mkdir -p dist
              # Copy source as fallback
              cp src/ccstatusline.ts dist/ccstatusline.js
            fi
          '';

          installPhase = ''
            mkdir -p $out/bin $out/lib/ccstatusline $out/share/ccstatusline

            # Copy source files for development
            cp -r src $out/share/ccstatusline/
            cp package.json $out/share/ccstatusline/
            
            # Copy built files if they exist
            if [ -d dist ]; then
              cp -r dist/* $out/lib/ccstatusline/
            fi

            # Create development wrapper
            cat > $out/bin/ccstatusline << 'EOF'
#!/usr/bin/env bash
# Development build - runs from source with Bun
cd ${placeholder "out"}/share/ccstatusline
if command -v bun >/dev/null 2>&1; then
  exec bun src/ccstatusline.ts "$@"
elif command -v node >/dev/null 2>&1 && [ -f ${placeholder "out"}/lib/ccstatusline/ccstatusline.js ]; then
  exec node ${placeholder "out"}/lib/ccstatusline/ccstatusline.js "$@"
else
  echo "Error: Bun or Node.js required to run ccstatusline" >&2
  echo "Install with: nix-env -iA nixpkgs.bun" >&2
  exit 1
fi
EOF
            chmod +x $out/bin/ccstatusline
          '';

          meta = with pkgs.lib; {
            description = "A customizable status line formatter for Claude Code CLI (development build)";
            homepage = "https://github.com/sirmalloc/ccstatusline";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.all;
          };
        };

      in
      {
        packages = {
          default = ccstatusline;
          ccstatusline = ccstatusline;
          dev = ccstatusline-dev;
        };

        apps = {
          default = flake-utils.lib.mkApp {
            drv = ccstatusline;
            name = "ccstatusline";
          };
          dev = flake-utils.lib.mkApp {
            drv = ccstatusline-dev;
            name = "ccstatusline";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Primary runtime
            bun
            
            # Alternative runtime for compatibility
            nodejs
            nodePackages.npm
            
            # Development tools
            typescript
            git
            
            # For development and testing
            nodePackages.patch-package
          ];

          shellHook = ''
            echo "🎨 ccstatusline development environment"
            echo ""
            echo "Available commands:"
            echo "  bun run src/ccstatusline.ts    # Run TUI configuration"
            echo "  bun run build                  # Build for distribution"
            echo "  bun install                    # Install dependencies"
            echo ""
            echo "To test with piped input:"
            echo '  echo '"'"'{"model":{"display_name":"Claude 3.5 Sonnet"},"transcript_path":"test.jsonl"}'"'"' | bun run src/ccstatusline.ts'
            echo ""
            echo "Nix usage:"
            echo "  nix run .#dev                  # Run development build"
            echo "  nix run                        # Run via npx (requires internet)"
            echo ""
            
            # Set up Bun cache in a writable location
            export BUN_INSTALL_CACHE_DIR="$PWD/.bun-cache"
          '';
        };
      });
}