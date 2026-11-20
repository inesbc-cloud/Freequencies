{
  description = "Freequencies: the coordination tool for Lisbon's independent culture, a fork of Scala's calendar view (pure QML over the scala core module)";

  inputs = {
    # The same builder the scala core and Scala's view use (Basecamp 0.3).
    logos-module-builder.url = "github:logos-co/logos-module-builder/0.3.1";
    # Nights are Scala events, read and written through the scala core (postExt/putEvent: 0.12.x).
    scala.url = "github:vpavlin/scala/ef7b1ffbb64ffe013717cbe2b4e65f22f4fa5ae6";
    # Scala's view (and so this fork) calls loam_core directly for identities and keycard enrolment.
    loam_core.url = "github:vpavlin/loam-basecamp/f66ad0ac8973a314f17eca12e4ce0b9939b1a19a?dir=core";
  };

  outputs = inputs@{ logos-module-builder, scala, loam_core, ... }:
    logos-module-builder.lib.mkLogosQmlModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
