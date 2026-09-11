# Optional: only needed for the CachyOS kernel + home-manager.
# Plain configuration.nix works without this file.
{
  description = "blackbox - HP Pavilion Gaming 15-dk1xxx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";   # CachyOS kernel
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, chaotic, home-manager, ... }: {
    nixosConfigurations.blackbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # --- CachyOS kernel (optional; drop these 2 lines for stock) ---
        chaotic.nixosModules.default
        { boot.kernelPackages = nixpkgs.legacyPackages.x86_64-linux.linuxPackages_cachyos; }

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.blackbox = import ./home.nix;
        }
      ];
    };
  };
}
