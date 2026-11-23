{
  description = "Freequencies: the coordination tool for Lisbon's independent culture, a fork of Scala's calendar view (pure QML over the scala core module)";

  inputs = {
    # The same builder the scala core and Scala's view use (Basecamp 0.3).
    logos-module-builder.url = "github:logos-co/logos-module-builder/0.3.1";
    # Nights are Scala events, read and written through the scala core (postExt/putEvent: 0.12.x).
    scala.url = "github:vpavlin/scala/ef7b1ffbb64ffe013717cbe2b4e65f22f4fa5ae6";
    # Scala's view (and so this fork) calls loam_core directly for identities and keycard enrolment.
    loam_core.url = "github:vpavlin/loam-basecamp/f66ad0ac8973a314f17eca12e4ce0b9939b1a19a?dir=core";
    # Artists and crew come from Kith's books through the kith core (ADR 0004); kith 0.3.1.
    kith.url = "github:vpavlin/kith/d338a7852374bcdba40a32dcec8f399d20b078c5";
    # Booking / crew / guest-list forms through the whisperbox_core module (ADR 0005); whisperbox_core 0.4.1.
    whisperbox_core.url = "github:vpavlin/whisperbox-logos/accc756bca592a6d76469dc0c86fa83e740d5a2b?dir=whisperbox_core";
    # Public listings: Freequencies' own background helper, next door in this repo (optional at runtime).
    freequencies_core.url = "path:../freequencies-core";
  };

  outputs = inputs@{ logos-module-builder, scala, loam_core, kith, whisperbox_core, freequencies_core, ... }:
    logos-module-builder.lib.mkLogosQmlModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
