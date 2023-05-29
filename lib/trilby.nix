{ inputs, lib, ... }:

with builtins;
rec {
  trilbyConfig = t: lib.pipe t [
    (t: {
      name = "trilby";
      edition = "workstation";
      channel = "unstable";
      hostPlatform = "x86_64-linux";
      buildPlatform = "x86_64-linux";
      variant = null;
      format = null;
    } // t)
    (t: t // rec {
      hostSystem = lib.systems.parse.mkSystemFromString t.hostPlatform;
      buildSystem = lib.systems.parse.mkSystemFromString t.buildPlatform;
      nixpkgs = inputs."nixpkgs-${t.channel}" // {
        nixosModules = lib.findModules "${inputs."nixpkgs-${t.channel}"}/nixos/modules";
      };
      release = nixpkgs.lib.trivial.release;
      configurationName = concatStringsSep "-" (filter (s: s != null && s != "") [
        t.name
        t.edition
        (concatStringsSep "_" (lib.splitString "." t.channel))
        hostSystem.cpu.name
        t.variant
        t.format
      ]);
    })
  ];

  trilbySystem = attrs:
    let
      trilby = trilbyConfig (attrs.trilby or { });
    in
    trilby.nixpkgs.lib.nixosSystem {
      modules = with inputs.self.nixosModules; [
        editions.${trilby.edition}
        hostPlatforms.${trilby.hostPlatform}
      ]
      ++ lib.optional (trilby ? format && !lib.isEmpty trilby.format) formats.${trilby.format}
      ++ lib.optional (trilby ? variant && !lib.isEmpty trilby.variant) formats.${trilby.variant}
      ++ attrs.modules or [ ];
      specialArgs = { inherit inputs lib trilby; };
    };
}
