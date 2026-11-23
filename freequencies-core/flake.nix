{
  description = "freequencies_core: fetches public event listings (official feeds only) for the Freequencies view.";
  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder/0.3.1";
  };
  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
