# Synth for Stata

Stata implementation of the **synthetic control method** for causal
inference in comparative case studies, by Alberto Abadie, Alexis
Diamond, and Jens Hainmueller.

The method is described in:

> Abadie, A., Diamond, A., & Hainmueller, J. (2010). "Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program." *Journal of the American Statistical Association*, 105(490), 493–505.
>
> Abadie, A., Diamond, A., & Hainmueller, J. (2011). "Synth: An R Package for Synthetic Control Methods in Comparative Case Studies." *Journal of Statistical Software*, 42(13), 1–17.
>
> Abadie, A., Diamond, A., & Hainmueller, J. (2014). "Comparative Politics and the Synthetic Control Method." *American Journal of Political Science*, 59(2), 495–510.

## Installation

From within Stata:

```
ssc install synth, all replace
```

Or net-install the development version directly from this repo:

```stata
net install synth, from(https://raw.githubusercontent.com/j-hai/synth-stata/main/s/) replace
```

When net-installing directly from GitHub, Stata installs the command,
help, plugin, and Mata files, but not the bundled example datasets.
To download `smoking.dta` and `germany.dta` into your current working
directory, run:

```stata
net get synth, from(https://raw.githubusercontent.com/j-hai/synth-stata/main/s/)
```

## Quick start

`smoking.dta` and `germany.dta` are not bundled with Stata; pull them
into your current working directory first via `net get` (see
Installation above) or download them directly from this repo.

```stata
use smoking, clear
tsset state year

synth cigsale beer(1984(1)1988) lnincome retprice age15to24 ///
              cigsale(1988) cigsale(1980) cigsale(1975), ///
              trunit(3) trperiod(1989) figure
```

The `figure` option draws the treated vs. synthetic-control trajectory.
After running `synth`, the standard returns are available:

* `e(RMSPE)` — root mean squared prediction error over the
  pre-intervention period
* `e(V_matrix)` — diagonal weights on predictors
* `e(W_weights)` — control-unit weights with names and ID numbers
* `e(X_balance)` — predictor balance: treated vs. synthetic
* `e(Y_treated)`, `e(Y_synthetic)` — outcome trajectories

## What's new in 0.0.8

* **Apple Silicon support.** Universal `synthopt.mac` binary now
  includes an arm64 slice; Stata 17+ on M-series Macs running natively
  no longer fails with `Could not load plugin: synthopt.plugin`.
* C source in `plugin-src/` now compiles cleanly on macOS, Linux, and
  Windows without manual edits (was Microsoft-specific before).
* Bumped `version` declaration from 9.2 to 13.0; numerous typo fixes
  in comments and error messages.

See [`NEWS.md`](NEWS.md) for the full change log.

## Repository layout

The repo mirrors SSC's letter-directory layout: `net install` delivers
the runnable package files, while `net get` downloads the bundled
example datasets.

```
s/                   # primary install dir (matches SSC's bocode/s/)
  synth.pkg          # SSC package descriptor
  synth.ado          # the user-facing command
  synth_ll.ado       # loss-function helper (used in nested mode)
  synth.sthlp        # in-Stata help text
  stata.toc          # SSC TOC
  smoking.dta        # canonical example dataset
  synthopt.mac       # macOS plugin (universal: arm64 + x86_64)
  synthopt.linux32   # Linux 32-bit plugin
  synthopt.linux64   # Linux 64-bit plugin
  synthopt.win32     # Windows 32-bit plugin
  synthopt.win64     # Windows 64-bit plugin
  synthopt.plugin    # platform-active plugin (set by installer)

g/
  germany.dta        # additional example dataset

l/
  lsynth_mata_subr.mlib  # compiled Mata routines

plugin-src/          # C source for the optimizer plugin
  synthopt.c, pr_loqo.{c,h}, stplugin.{c,h}

dev/                 # development tooling — not shipped
  01_capture_baseline.do   # records the 0.0-7 reference output
  02_regression_check.do   # re-runs and diffs against baseline
  baseline_0.0-7.txt       # frozen reference (RMSPE, V, W, X)
```

## Building the plugin from source

```sh
cd plugin-src

# macOS (universal arm64 + x86_64)
cc -arch arm64 -arch x86_64 -bundle -fPIC -DSYSTEM=APPLEMAC -O2 \
   -o ../synthopt.mac stplugin.c synthopt.c pr_loqo.c

# Linux x86_64
cc -shared -fPIC -DSYSTEM=OPUNIX -O2 \
   -o ../synthopt.linux64 stplugin.c synthopt.c pr_loqo.c
```

Windows builds use the original Visual Studio solution under the
authoritative source tree (not in this repo).

## License

GPL (>= 2). Plugin source `pr_loqo.c` was written by Alex J. Smola
(GMD Berlin, 1997) and adapted for R by Ralf Herbrich; used here under
its original terms.
