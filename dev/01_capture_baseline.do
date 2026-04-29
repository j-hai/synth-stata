*! Capture golden-baseline outputs from Synth Stata 0.0-7 (frozen reference).
*!
*! Runs the canonical smoking example using the source files in the repo
*! root (synth.ado / synth_ll.ado / synthopt.plugin / lsynth_mata_subr.mlib),
*! captures the V matrix, W weights, RMSPE, and predictor balance, and
*! writes them to dev/baseline_0.0-7.txt for later regression testing.
*!
*! How to run (from repo root):
*!   /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do dev/01_capture_baseline.do
*!
*! Output:  dev/baseline_0.0-7.txt
*!          dev/baseline_0.0-7.log

clear all
set more off
set seed 20260429

* --------------------------------------------------------------------------
* point Stata at the source files in the repo root (so we test those, not a
* user-installed copy)
* --------------------------------------------------------------------------
adopath ++ "`c(pwd)'"

* sanity-check version
which synth
which synth_ll

* --------------------------------------------------------------------------
* canonical smoking example (Abadie, Diamond & Hainmueller 2010 JASA)
* --------------------------------------------------------------------------
use "smoking.dta", clear
tsset state year

log using "dev/baseline_0.0-7.log", replace text

synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) ///
        cigsale(1980) cigsale(1975), trunit(3) trperiod(1989)

log close

* --------------------------------------------------------------------------
* dump key results to a stable text file for regression comparison
* --------------------------------------------------------------------------
file open out using "dev/baseline_0.0-7.txt", write replace text

file write out "Synth Stata baseline -- frozen 0.0-7 reference" _n _n

file write out "---- e(RMSPE) ----" _n
mat list e(RMSPE), format(%14.10f)
mat L = e(RMSPE)
forv i = 1/`=rowsof(L)' {
  forv j = 1/`=colsof(L)' {
    file write out %20.10f (L[`i',`j']) _n
  }
}

file write out _n "---- e(V_matrix) ----" _n
mat V = e(V_matrix)
forv i = 1/`=rowsof(V)' {
  forv j = 1/`=colsof(V)' {
    file write out %20.10f (V[`i',`j']) " "
  }
  file write out _n
}

file write out _n "---- e(W_weights) ----" _n
mat W = e(W_weights)
forv i = 1/`=rowsof(W)' {
  forv j = 1/`=colsof(W)' {
    file write out %20.10f (W[`i',`j']) " "
  }
  file write out _n
}

file write out _n "---- e(X_balance) ----" _n
mat X = e(X_balance)
forv i = 1/`=rowsof(X)' {
  forv j = 1/`=colsof(X)' {
    file write out %20.10f (X[`i',`j']) " "
  }
  file write out _n
}

file close out

display "Wrote dev/baseline_0.0-7.txt and dev/baseline_0.0-7.log"
