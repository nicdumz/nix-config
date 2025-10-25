# Requirements

A brief list of requirements so we understand what the solution will look like:

- [Configuration](model.md#configuration) MUST be versioned publicly.
  - Versioned for all the goodness that comes with it (tracking why a particular changes landed,
    when, in which context.)
  - I want to be part of an open ecosystem. I want to contribute to the set of configurations that
    Internet strangers can look up on GitHub and learn from. (`"path:*.nix something"` is a regular
    GitHub search query of mine when I develop on Nix / NixOS).
- System deployments or new machine installs MUST be
  [reproducible](https://en.wikipedia.org/wiki/Reproducible_builds) and deterministic.
  - Importantly, if I deploy my system at a given Git revision, I get exactly the same output
    everytime. This allows for trivial pain-free rollbacks.
- Updates (security updates, OS updates, individual software version updates) MUST not break my
  systems.
  - Critical security updates MUST apply at least weekly.
  - If a new version of a dependency becomes incompatible with my configuration, the `deploy` step
    SHOULD fail before changing my systems. When this is not feasible, rollbacks to an earlier Git
    revision MUST be a viable recovery path.

Non-functional:

- It's easy for me to adhere to my philosophy and [modeling](model.md) principles, separating
  data/state into one of my 6 pre-defined categories.
