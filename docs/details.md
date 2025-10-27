# Details

## Critical updates

NixOS provides us with deterministic, reproducible "generations" for your operating system. At the
same time we did say that we wanted to pick up regular upstream changes, critical security and other
fixes. This seems at odds with the idea of a "static" configuration repository describing an
unchanging final intent.

Upstream repositories (`nixpkgs`) release regular changes on a stable branch, we "only" have to pick
up those new changes.

Because everything is versioned, this requires automated repository changes, similarly to
`Dependabot` and `Renovate` bots picking up the latest versions of npm packages and updating
`package.json` in repositories.

I have a small
[GitHub action](https://github.com/nicdumz/nix-config/blob/main/.github/workflows/update-flake-lock.yml)
taking care of this task for me. Note that **unlike** the npm ecosystem picking up versions from
head (and what this means for security and reliability), I only track the stable version of
`nixpkgs`/`NixOS`, which mitigates risks somewhat.

## Continuous Integration and Caching

For each Pull Request (including the aforementioned automated updates) I rebuild entirely all of my
systems (!) and validate that no major assertions trigger during the build process.

This may sound like a very expensive step to do as part of CI, but because of the distributed
caching, this is actually rather affordable.

As a bonus effect: a change going through CI will pre-warm the distributed caches, guaranteeing that
subsequent updates on my machines will be able to fetch already built artefacts already.

Nix package maintainers will include some verifications over configuration, giving builds a chance
to fail before booting the system on a broken generation. I wouldn't say that this is foolproof
though, perhaps 1 upgrade in 10 may result in broken generation. A broken generation on NixOS is
however a non-event as you can simply select the previous generation in the `systemd-boot` menu.

## Major OS upgrades

Twice a year, NixOS releases new versions. Upgrading is very similar to the automated upgrades I
mentioned above (tracking a new upstream branch), and are just as uneventful, so far.

Worst case, I can roll back (in my boot menu) to the previous generation if I fail to boot into the
latest version.

## NixOS for my router

I own a Linux box which does some 10G routing, and acts as a media server, all for the benefit of
the household.

I cannot afford to break this box for long. That being said, once again, most of the time even a
scary outage can just be fixed by a power reset on the box, booting back into the previous NixOS
generation.

## Secrets on the open Internet

I had to check into my repository a few secrets, for instance generated SSH keys, or user passwords,
in order to have a deterministic setup.

There are easy ways to do this safely nowadays when you own enough FIDO2 keys. Simply put, you can
encrypt your secrets for your FIDO2 key's identities. When provisioning a new host, you can rewrap
those secrets (one security key touch!) to re-encrypt them for the target host.
