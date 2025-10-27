# Conclusion

Ultimately, the combination of Nix and NixOS is more than just a configuration tool; it's a paradigm
shift towards an immutable, declarative infrastructure model.

This model is quite similar to how I'm used to thinking of production at work, and I'm surprised it
took me so long to figure out I could do such a thing at home.

## Debian pales in comparison

I used to run all of my home machines (laptop, workstations, router) on Debian. I unfortunately
regularly had events where on a day where you really need your machine, Debian boots up with a
broken graphics driver and/or no audio after a magical "stable" critical update, to great
frustration, and without any easy way to diagnose quickly what happened.

## I won't be going back

A year into my experiment, I am now very sure.

Mark my words: there is no way I will be running an Operating System that's not declarative. Perhaps
I'll be switching to a future OS generation, better than NixOS, but a declarative, intent based
configuration model seems to be the one and only way.
