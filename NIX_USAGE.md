# Using ccstatusline with Nix

This flake provides multiple ways to install and use ccstatusline on NixOS and other Nix-based systems.

## Installation Options

### 1. Direct Installation (Recommended)

Install ccstatusline to your user profile:

```bash
nix profile install github:sirmalloc/ccstatusline
```

This installs a wrapper that uses `npx` to run the latest version with all dependencies.

### 2. Temporary Usage

Run ccstatusline without installing:

```bash
# Run the configuration TUI
nix run github:sirmalloc/ccstatusline

# Run with piped input
echo '{"model":{"display_name":"Claude 3.5 Sonnet"},"transcript_path":"test.jsonl"}' | nix run github:sirmalloc/ccstatusline
```

### 3. Development Environment

Enter a development shell with all dependencies:

```bash
# Clone the repository first
git clone https://github.com/sirmalloc/ccstatusline.git
cd ccstatusline

# Enter development shell
nix develop

# Now you can run:
bun install
bun run src/ccstatusline.ts
```

### 4. NixOS System-wide Installation

Add to your NixOS configuration:

```nix
# configuration.nix
{
  environment.systemPackages = [
    (builtins.getFlake "github:sirmalloc/ccstatusline").packages.${pkgs.system}.default
  ];
}
```

Or using flakes in your system configuration:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ccstatusline.url = "github:sirmalloc/ccstatusline";
  };

  outputs = { self, nixpkgs, ccstatusline }: {
    nixosConfigurations.your-system = nixpkgs.lib.nixosSystem {
      modules = [
        {
          environment.systemPackages = [
            ccstatusline.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

## Available Packages

- `default` / `ccstatusline`: Wrapper that uses npx (requires internet on first run)
- `dev`: Development build from source (for contributors)

## Dependencies

The default package automatically includes:
- Node.js (for npx/npm)
- Bun (fallback runtime)

The development shell additionally includes:
- TypeScript
- Git
- patch-package

## Usage After Installation

Once installed, use ccstatusline exactly as described in the main README:

```bash
# Run configuration TUI
ccstatusline

# Test with piped input  
echo '{"model":{"display_name":"Claude 3.5 Sonnet"},"transcript_path":"test.jsonl"}' | ccstatusline
```

## Troubleshooting

### Network Issues
The default package requires internet access on first run to download dependencies via npx. If you're in an offline environment, consider:
1. Pre-downloading with `npx ccstatusline@latest` while online
2. Using the development build: `nix run .#dev` (after cloning the repo)

### Permission Issues
If you encounter permission issues, ensure your user has access to npm's global cache or use the development environment.

### Missing Dependencies
If you see "command not found" errors, ensure Node.js is available:
```bash
nix-env -iA nixpkgs.nodejs
# or add nodejs to your system packages
```