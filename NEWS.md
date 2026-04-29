# Synth for Stata 0.0.8

## Apple Silicon support

* **`synthopt.mac` is now a universal binary with arm64 + x86_64 slices.**
  Previously the binary covered `i386 / x86_64 / ppc_7400 / ppc64`, so
  Stata 17+ running natively on Apple Silicon failed to load the
  optimizer plugin with `Could not load plugin: synthopt.plugin`. The
  plugin is now built fresh from `plugin-src/` for both architectures.
* `synth.pkg` adds a `MACAPPLESIL` mapping so the SSC installer copies
  the correct binary on M-series Macs.

## C portability fixes (in `plugin-src/`)

These three issues prevented the plugin from compiling on macOS or
Linux without manual edits:

* `synthopt.c`: `#include <malloc.h>` -> `#include <stdlib.h>`.
  `<malloc.h>` is not portable; `malloc`/`calloc`/`free` live in
  `<stdlib.h>` per ISO C.
* `synthopt.c`: `sprintf_s` -> `snprintf` shim. The Microsoft Annex K
  function is now wrapped with a portable macro on non-MSVC compilers.
* `pr_loqo.c`: explicit `min`/`max` macros added at the top of the
  file. Previously the code relied on the compile environment to
  inject them, which fails on macOS/Linux.

## Quality-of-life

* `synth.ado`: `version` declaration bumped from 9.2 (Stata 9, 2007) to
  13.0 (Stata 13, 2013). All Stata releases since 2013 support v13
  syntax; this stops Stata from interpreting the code under a 17-year-
  old compatibility layer.
* Numerous typo fixes in comments and a couple of error/output messages
  ("speperate"/"separate", "paranthesis"/"parenthesis", "wheter"/
  "whether", "varibale"/"variable", "aynthing"/"anything",
  "leat one predictor is pecified"/"least one predictor is specified",
  "accoringly"/"accordingly", "disentagngle"/"disentangle",
  "articifical"/"artificial", "liklihood"/"likelihood").
* Bumped `synth.ado` `*!version` header from 0.0.7 (Jan 2014) to 0.0.8.

## Verified

The canonical smoking example (Abadie, Diamond, Hainmueller 2010 JASA)
reproduces byte-for-byte against the 0.0-7 baseline:

* `e(RMSPE)` = 1.9432331649 (unchanged)
* `e(V_matrix)`, `e(W_weights)`, `e(X_balance)`: all identical to 10
  decimal places.

See `dev/01_capture_baseline.do` and `dev/02_regression_check.do` for
the test harness.
