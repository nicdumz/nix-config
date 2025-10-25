# Model

I personally find that my systems configuration have been difficult to model and maintain in part
because we don't spend time separating and defining what belongs where. So let's try to do this a
bit formally for once.

I claim that on a system, you should only have 6 categories of state: Configuration, Cache, Data,
Provisioning state, Telemetry, and Ephemeral. You should always be aware of what category you're
working with, and act accordingly -- it'll make your life a lot easier in the long run.

Let's get into it.

## Configuration

:memo: **Versioned.**

The obvious one in an IaC setup: your intent configuration is where you describe the final state of
your systems. It should be versioned. In my case this is
[nicdumz/nix-config](https://github.com/nicdumz/nix-config).

## Cache

:memo: **Persisted locally**, but OK to lose and rebuild.

In my mental model, "Cache" is for artefacts and data that can be recomputed or downloaded again.
The only cost to losing "cache" is having to spend compute or network resources to rebuild it again.

Examples:

- If you use a browser sync feature, your browsing history is only "cache": you only have to sign
  into your sync'ed profile to retrieve locally all of your browser's state.
- Any Git repo can be fetched again from its authoritative source.
- Any large ISO can be downloaded/torrented again.
- Binary packages, or outputs of reproducible compilations or transformations in general, can be
  modeled as Cache: one "only" has to recompile them or to re-execute the transformation to rebuild
  state.

## Data

:memo: **Back it up** or you'll lose it.

Your family photos? The output of a very expensive to train ML model? Anytime you are the author of
data, you are responsible for adequately organizing backups, from the source of the data, to
reasonable redundant replicas, depending on the importance of this data.

If you don't back this up or don't test your recovery story? You lose this data.

## Provisioning state

:memo: **Randomized at install time**, regenerating it must be fine.

When installing a new machine, some aspects will be randomly generated or specific to the particular
deployment. As an example, you will most likely generate a local SSH key for the host, or disk
partitioning will assign distinct UUIDs to disk partitions.

In general these aspects are random, generated during the first installation of your machine, and
must not change the overall behavior of your system. This means that it's fine to have different
provisioning state across installs, and to lose this state on re-provisioning.

Some nuances:

- The hostname of a machine, to me, is not part of provisioning state as it can be determined in
  advance, and should be part of [Configuration](#configuration).
- While it may be needed to generate a private SSH key during machine deployment/provisioning, that
  SSH key is not what I want to be referring to in my Configuration, as it will change across
  machine installs. Instead, I version (encrypted) SSH private/public keypairs for my hosts in my
  Configuration, and deploy them to my hosts after initial provisioning.

## Telemetry, Observability {#telemetry}

:memo: **Observability**, may or may not persist across reboots or reinstalls.

System logs, console outputs. All of those help me diagnose what happened to a system. Ideally I
should collect this data, aggregate it, and process it outside of the originating machines (with
[Vector](https://vector.dev/) or whichever Observability suite you like). In an idealized system I
should even use this to build monitoring and alerting.

On the other hand, losing this state "only" removes understanding on my system. Depending on
tradeoffs, I sometimes keep this data local to machines, do not necessarily back it up, and
sometimes this data does not even survive a reboot.

## Default, everything else: Ephemeral {#ephemeral}

:memo: **Wiped on reboots.**

The Beyonce rule applies: "if you liked it you should have versioned it" (or backed it up).

[Erase your darlings](https://grahamc.com/blog/erase-your-darlings/) and
[tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/) were strong motivators here:
there should be no in-between "oh what is this `/home/foo/important.sh` file doing here" moments
when maintaining my systems. All of the changes should be done first and foremost in the
[configuration](#configuration) plane. Direct changes to machines will be ephemeral and lost on
reboots, by design: don't do it, you'll only regret it.

Similarly, if a process dumps data in a directory and expects it back on reboots? Too bad. This is a
sign of misconfiguration / lacking an abstraction, and will break by design, until I fix it.
