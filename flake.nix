{
  description = "A collection of of-the-star's opinionated nix flake templates";

  outputs =
    {
      self,
    }:
    {
      templates = {
        default = {
          path = ./default;
          description = "A basic flake for development environments and packaging";
        };

        rust = {
          path = ./rust;
          description = "A rust development flake that adds the necessary tooling and development environment for excellent automation";
        };

        python = {
          path = ./python;
          description = "A python development flake";
        };

        arduino = {
          path = ./arduino;
          description = "A rust development flake for targeting the Arduino Uno";
          welcomeText = ''
            # A flake-based Arduino Uno Rust workflow

            Before you start, run 

            ```sh
            nix run .#updateSrc
            ```

            to vendor the core dependencies and run it each time you update the lockfile.
          '';
        };
      };
    };
}
