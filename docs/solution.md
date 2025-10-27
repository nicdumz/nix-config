# Solution

I'm using NixOS on all of my machines since end of 2024. An explanation of the involved pieces and
how they all fit together.

I've asked AI to write a teaser on why NixOS is cool, and I believe it did a pretty good job:

{==

What if you could try a massive system update, and if it broke anything—your Wi-Fi, your monitor, a
key app—you could roll back your entire operating system to its previous, perfect state with a
single reboot?

That's the magic of NixOS.

It treats your whole OS as a single "package." This means:

- Atomic Updates & Rollbacks: Every upgrade creates a new "generation" of your system. If you don't
  like it, your old one is still there, ready to be booted.

- No More "Configuration Drift": Your system is built only from your versioned config files. You
  can't just temporarily hack a file in `/etc/` and forget about it. This ends the "what did I
  change to make this work?" nightmare. Your versioned configuration is your system's single source
  of truth.

==}

## Configuration language: Nix expression language {#nix}

I believe that most configuration languages are created equal. Some syntax to produce key-value
pairs, more or less. Syntactic sugar to avoid repetitions, but that's it.

There's a 101 blog entry [here](https://www.christophercoverdale.com/blog/nix-101-part-1/), but that
part in my opinion is quite boring.

Nonetheless, all of the configurations are written in a collection of versioned `.nix` files, and
that are various ways to organize your configuration in a modular fashion.

Some examples from my configuration:

- [How I configure VSCode](https://github.com/nicdumz/nix-config/blob/main/nix/modules/home/apps/vscode/default.nix)
  (only enabled on headful machines).
- [How I configure Grafana](https://github.com/nicdumz/nix-config/blob/main/nix/modules/nixos/services/observability/grafana/default.nix)
  (only enabled on the router machine).

## Nix packages

Using the Nix language, one can define "derivations", which are recipes for reproducible
transformations. Each derivation describes "build steps" which takes a set of inputs and transforms
them into outputs.

Derivations are then used to build "packages", very similarly to software packages in a regular
distribution, e.g. Debian.

I think it's easier to look at an existing package to understand what happens.
[This](https://github.com/NixOS/nixpkgs/blob/4ea513ffb46058baad9cd921c5cee04fea30944c/pkgs/applications/editors/kakoune/default.nix)
package would fetch the source, via Github, of the `kakoune` editor, and `make; make install` for
that package, producing an expected `kakoune` binary.

**I never have to write my own packages**. The NixOS community maintains a central repository of
packages at [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs). All put together, this makes a kind
of "Source distribution", not too different from Gentoo where users have to recompile binaries on
each update.

Unlike Gentoo however, you rarely have to recompile packages, because the language around
derivations forces output to be reproducible and deterministic:

## Package outputs

All of my systems have a `/nix/store` folder, the "Nix Store":

```sh title="Inside the Nix Store"
$ ls /nix/store/ | head
0a1yz9lgzly1qdj2464gr1lmz2zpnxkl-libtool-2.4.7.drv
0a2kbdrcsnmll5jndv98g63y83jzwhzi-gvfs-1.57.2
0a2yia3avaw4n7sq9blfhjkw9bwaz845-umockdev-0.19.1.drv
0a3facj8mq31kmazfh1ys00vwsqmwk7a-mdbook-linkcheck-0.7.7-vendor.tar.gz.drv
0a4di192p2vbkvvq1skin6bx211vidrx-libXfont-1.5.4.drv
0a4wbzik10grldjx3hcadzg337anzk5b-home-manager-path
0a5m3qldpclgpbak4mkwlv5182sd1ax7-skylighting-core-0.14.5.drv
0a7ddzdi7l58ay9vix4xzmvslnp31my9-Module-Runtime-0.016.tar.gz.drv
0a7mfnca025rzk58ws0n7q47qpvjpcy3-libdvdread-6.1.3.drv
```

Those are outputs of derivations, using content-based path prefixes. The output of a derivation can
be predicted from a nix package definition, meaning that:

- Users needing to depend on a package's output can simply link to the expected nix store path
  output.
- **Local caching**: When deploying a new version of the system, if the derivation output already
  exists in the Nix Store, then there is no need to recreate it ("re-compile it").
- **Distributed remote caching**: Users of Nix can share the output of computations on a networked
  cache ([https://cache.nixos.org/](https://cache.nixos.org/))

The Nix store is essentially immutable -- paths are read-only to all users, and a path is only
garbage collected if nothing refers to it.

## Package manager

Let's start simple, imagine that you want to use the output of Nix packages in your $PATH. We know
that the outputs are in the Nix store and can be content-addressed. You could then... simply add the
raw paths to your $PATH. In fact, the Nix package manager does something similar. It sets up
symlinks against Store paths in a "profile":

```sh title="User (PATH) profiles"
$ ls -la /etc/profiles/per-user/ndumazet/bin/
...
lrwxrwxrwx - root  1 Jan  1970 git -> /nix/store/7kh7s643w6brdzmbk28pzk5z13zgcbax-home-manager-path/bin/git
...
lrwxrwxrwx - root  1 Jan  1970 nvim -> /nix/store/7kh7s643w6brdzmbk28pzk5z13zgcbax-home-manager-path/bin/nvim
# There are a few of those
$ ls -la /etc/profiles/per-user/ndumazet/bin/ | wc -l
45
```

And `/etc/profiles/per-user/ndumazet/bin` is in my `$PATH`.

I've simplified a lot, but this is essentially how the NixOS ecosystem will be managing resources
and binaries.

Under the hood, you can imagine that all binaries are in fact statically linked or point to library
paths which refer to Nix store paths. A corollary is that it becomes trivial to install several
versions of a binary which all require distinct versions of a library, without risking the integrity
of your system. This completely solves the "dependency hell" type of problems. You don't need tools
like `virtualenv` just to manage different project requirements; Nix handles it at the operating
system level.

## NixOS

`NixOS` is an operating system building on all of the above.

My system can currently boot 3 generations:

```sh title="System profiles"
$ ls -la /nix/var/nix/profiles
lrwxrwxrwx - root  3 Jan 21:25 default -> /nix/var/nix/profiles/per-user/root/profile
drwxr-xr-x - root  3 Jan 17:43 per-user
lrwxrwxrwx - root 25 Oct 06:57 system -> system-234-link
lrwxrwxrwx - root  6 Sep 08:28 system-223-link -> /nix/store/m3x7xfxrydw8kamk31ky3vgs567daibx-nixos-system-bistannix-25.05.20250904.fe83bbd
lrwxrwxrwx - root 19 Oct 15:10 system-233-link -> /nix/store/cihzg1vqz4m0g16w8lkglvbb9vjvm2i3-nixos-system-bistannix-25.05.20251016.98ff3f9-flake.20251019.e7299b0
lrwxrwxrwx - root 25 Oct 06:57 system-234-link -> /nix/store/0syb258lyj0kfamd7i7kwi0r98b99vrj-nixos-system-bistannix-25.05.20251021.481cf55-flake.20251023.0febaec
```

Each generation (`system-${gen}-link`) points to a Store path, which is an immutable directory to a
top level "system package".

What's inside that Store directory path? A root-like filesystem, with more symlinks into the nix
store:

```sh title="Inside a profile"
$ ls -la /nix/var/nix/profiles/system-233-link/
.r-xr-xr-x 8.3k root  1 Jan  1970 activate
lrwxrwxrwx    - root  1 Jan  1970 append-initrd-secrets -> /nix/store/854r1y7ds8gpb590ykp80pp8abxvh8rz-append-initrd-secrets/bin/append-initrd-secrets
dr-xr-xr-x    - root  1 Jan  1970 bin
.r--r--r--  789 root  1 Jan  1970 boot.json
.r-xr-xr-x 3.4k root  1 Jan  1970 dry-activate
lrwxrwxrwx    - root  1 Jan  1970 etc -> /nix/store/x625sh59bplvfq71rmh93i5mi762fc9a-etc/etc
.r--r--r--    0 root  1 Jan  1970 extra-dependencies
lrwxrwxrwx    - root  1 Jan  1970 firmware -> /nix/store/ikkg1182hfwpghgh3afp16nmw3q3zclr-firmware/lib/firmware
.r-xr-xr-x 172k root  1 Jan  1970 init
.r--r--r--    9 root  1 Jan  1970 init-interface-version
lrwxrwxrwx    - root  1 Jan  1970 initrd -> /nix/store/04abzzbp0rymax41i7qgwrrlqvwh8ajl-initrd-linux-6.12.53/initrd
lrwxrwxrwx    - root  1 Jan  1970 kernel -> /nix/store/z05bjh6ihlb04v2l1id59baxk1qdxpdz-linux-6.12.53/bzImage
lrwxrwxrwx    - root  1 Jan  1970 kernel-modules -> /nix/store/kmh5d3qv20n5l4y96q63agjf552a5xmi-linux-6.12.53-modules
.r--r--r--   43 root  1 Jan  1970 kernel-params
.r--r--r--   45 root  1 Jan  1970 nixos-version
.r-xr-xr-x 4.4k root  1 Jan  1970 prepare-root
dr-xr-xr-x    - root  1 Jan  1970 specialisation
lrwxrwxrwx    - root  1 Jan  1970 sw -> /nix/store/4vmgbxnmsd7wi550f3va9m48shadqrwv-system-path
.r--r--r--   12 root  1 Jan  1970 system
lrwxrwxrwx    - root  1 Jan  1970 systemd -> /nix/store/d84f8nm2na5cr53m4jk0qk2mj7lgr9fx-systemd-257.9
```

You can see the usual initramfs, kernel, which you would expect on other distributions.

Put together, this means that each `/nix/var/nix/profiles/system-${gen}-link/` path is an immutable
version of linux distribution, at generation `${gen}`.

- When booting up, systemd-boot presents those 3 generations in a boot menu, and the boot sequence
  will deploy the selected, particular system's generation.
- When upgrading your system, you will first build all your dependencies, create the root
  filesystem, and the upgrade process will atomically swap to another generation, by overwriting a
  couple symlinks.

## `/` is mostly a tmpfs

Inspired by [Erase your darlings](https://grahamc.com/blog/erase-your-darlings/) and
[tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/), `/` root filesystem is not
persistent.

There are particular mountpoints, e.g. `/nix/` mentioned above, which survive reboots, but the vast
majority of the filesystem is ephemeral or a long tree of links:

```sh title="Where is sshd_config"
$ ls -la /etc/ssh/sshd_config
lrwxrwxrwx - root 27 Oct 17:41 /etc/ssh/sshd_config -> /etc/static/ssh/sshd_config
$ ls -la /etc/static/ssh/sshd_config
lrwxrwxrwx - root  1 Jan  1970 /etc/static/ssh/sshd_config -> /nix/store/lvb4syxyhzdjzqvxklb87kvzzygpfiny-sshd.conf-final
$ ls -la /nix/store/lvb4syxyhzdjzqvxklb87kvzzygpfiny-sshd.conf-final
.r--r--r-- 975 root  1 Jan  1970 /nix/store/lvb4syxyhzdjzqvxklb87kvzzygpfiny-sshd.conf-final
```

This solution elegantly prevents me from hacking configuration files directly. For example,
`/etc/ssh/sshd_config` is just a symlink pointing (indirectly) to a read-only file in `/nix/store/`.
If I need to change a setting, I must go to the intent source, modify the versioned .nix file, and
rebuild my system.
