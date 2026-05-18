{
    description = "Gavri's NixOS Flake Config";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        stylix.url = "github:danth/stylix";
        noctalia = {
          url = "github:noctalia-dev/noctalia-shell";
          inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, stylix, ...}@inputs:
    {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
                ./configuration.nix
                home-manager.nixosModules.home-manager
                stylix.nixosModules.stylix
                {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.backupFileExtension = "backup";
                    home-manager.users.gavri = import ./home.nix;
                    home-manager.sharedModules = [ inputs.noctalia.homeModules.default ];
                }
                ./noctalia.nix
            ];
        };
    };
}
