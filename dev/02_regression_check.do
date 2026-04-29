*! Regression check: current dev source vs. dev/baseline_0.0-7.txt
*!
*! Re-runs the canonical smoking example from 01_capture_baseline.do and
*! writes the same matrix dump to dev/current.txt. Then a final diff
*! between dev/baseline_0.0-7.txt and dev/current.txt is the truth test.
*!
*! How to run (from repo root):
*!   /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do dev/02_regression_check.do
*!   diff dev/baseline_0.0-7.txt dev/current.txt
*!
*! A clean diff means current code reproduces the 0.0-7 baseline byte-for-byte
*! within the 10 decimal places we serialize.

clear all
set more off
set seed 20260429

adopath ++ "`c(pwd)'"

use "smoking.dta", clear
tsset state year

log using "dev/current.log", replace text

synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) ///
        cigsale(1980) cigsale(1975), trunit(3) trperiod(1989)

log close

file open out using "dev/current.txt", write replace text

file write out "Synth Stata baseline -- frozen 0.0-7 reference" _n _n

file write out "---- e(RMSPE) ----" _n
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

display "Wrote dev/current.txt; diff against dev/baseline_0.0-7.txt to check regression"
