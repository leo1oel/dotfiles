{
  description = "leonardo's dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Function to create home-manager configuration for a given system
      mkHomeConfiguration = system: username: homeDirectory:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "24.05";

              # Common packages across all platforms
              home.packages = with pkgs; [
                # CLI tools
                bat
                ripgrep
                fd
                fzf
                zoxide
                eza

                # Git tools
                git
                git-lfs
                delta

                # Editors
                neovim
                helix

                # Development tools
                direnv
                jq

                # Terminal
                starship
                tmux

                # Python
                uv
                nvitop  # NVIDIA GPU monitoring tool

                # Node.js
                fnm

                # Other
                awscli2
                fastfetch
                openssh
              ];

              programs.home-manager.enable = true;
            }
          ];
        };
    in
    {
      # Linux configurations
      homeConfigurations = {
        # x86_64 Linux
        "leonardo@x86_64-linux" = mkHomeConfiguration "x86_64-linux" "leonardo" "/home/leonardo";

        # ARM64 Linux (e.g., Raspberry Pi, AWS Graviton)
        "leonardo@aarch64-linux" = mkHomeConfiguration "aarch64-linux" "leonardo" "/home/leonardo";

        # macOS Intel
        "leonardo@x86_64-darwin" = mkHomeConfiguration "x86_64-darwin" "leonardo" "/Users/leonardo";

        # macOS Apple Silicon
        "leonardo@aarch64-darwin" = mkHomeConfiguration "aarch64-darwin" "leonardo" "/Users/leonardo";

        # Default configuration (detects current system)
        leonardo = mkHomeConfiguration
          (if builtins.currentSystem == "x86_64-linux" then "x86_64-linux"
           else if builtins.currentSystem == "aarch64-linux" then "aarch64-linux"
           else if builtins.currentSystem == "x86_64-darwin" then "x86_64-darwin"
           else if builtins.currentSystem == "aarch64-darwin" then "aarch64-darwin"
           else builtins.currentSystem)
          "leonardo"
          (if builtins.elem builtins.currentSystem ["x86_64-darwin" "aarch64-darwin"]
           then "/Users/leonardo"
           else "/home/leonardo");
      };
    };
}
