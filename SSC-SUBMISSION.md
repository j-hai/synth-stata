# Submitting Synth 0.0.8 to SSC

The Stata `synth` package is distributed via SSC (Statistical Software
Components, hosted at Boston College by Kit Baum). To update the SSC
copy with this 0.0.8 release, you (the maintainer) need to email Kit
with the new files. The standard SSC procedure:

## Files to send

Bundle these into a zip and attach to the email:

* `synth.ado`
* `synth_ll.ado`
* `synth.sthlp`
* `synth.pkg`
* `stata.toc`
* `lsynth_mata_subr.mlib`
* `synthopt.mac`     (now universal arm64 + x86_64; the headline change)
* `synthopt.linux32`
* `synthopt.linux64`
* `synthopt.win32`
* `synthopt.win64`
* `smoking.dta`
* `germany.dta`

Don't send `synthopt.plugin` itself — that's the platform-active
symlink that the SSC installer creates from the appropriate platform
binary at install time, per the `g` lines in `synth.pkg`.

## Email template

To: `kit.baum@bc.edu` (the SSC maintainer)
Subject: `synth update — version 0.0.8`

```
Dear Kit,

Please find attached an updated version (0.0.8) of the synth package
for SSC. The headline change is Apple Silicon support — the
universal Mach-O binary previously shipped covered i386 / x86_64 /
ppc_7400 / ppc64 only, with no arm64 slice. Stata 17+ users on
M-series Macs running natively therefore got 'Could not load plugin:
synthopt.plugin' on every invocation. The updated synthopt.mac is a
universal binary with arm64 and x86_64 slices, built fresh from the
authoritative C source.

Other changes:
* synth.pkg adds a MACAPPLESIL mapping for the SSC installer.
* synth.ado: version 9.2 -> 13.0, plus a number of typo fixes in
  comments and error/output strings. No numerical results changed
  (verified byte-for-byte against the 0.0.7 baseline on the
  canonical Abadie-Diamond-Hainmueller 2010 smoking example).
* C source in plugin-src/ now compiles cleanly on macOS, Linux, and
  Windows without manual edits — three issues fixed: <malloc.h> ->
  <stdlib.h>, sprintf_s portably wrapped to snprintf, explicit
  min/max macros added to pr_loqo.c.

Source repository (with full change log and test harness):
https://github.com/j-hai/synth-stata

Best,
Jens Hainmueller
jhain@stanford.edu
```

## How to package the zip

From this repo's working tree (Stata 17+ on macOS so the `synthopt.mac`
binary is the universal one we just built):

```sh
cd /Users/jhainmueller/Documents/GitHub/synth-stata
zip -r /tmp/synth-0.0.8-ssc.zip \
  synth.ado synth_ll.ado synth.sthlp synth.pkg stata.toc \
  lsynth_mata_subr.mlib \
  synthopt.mac synthopt.linux32 synthopt.linux64 \
  synthopt.win32 synthopt.win64 \
  smoking.dta germany.dta
```

That zip is what attaches to the email.

## After Kit confirms

Kit usually replies within a day or two with confirmation. Once the
SSC copy is updated:

1. Tag the release on GitHub:
   ```
   git tag -a v0.0.8 -m "SSC release 0.0.8"
   git push origin v0.0.8
   ```
2. Optionally announce on Statalist or your own channels.

## Test users can do before SSC is live

The repo is already net-installable directly:

```stata
net install synth, from(https://raw.githubusercontent.com/j-hai/synth-stata/main/s/) replace
```

So users blocked by the Apple Silicon issue today can switch to the
GitHub source while the SSC update is in flight.
