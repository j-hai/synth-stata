*! Integration tests for synth — broader coverage than baseline.
*!
*! Exercises the main option paths so a refactor that breaks one of them
*! is caught even if the basic smoking baseline still reproduces:
*!
*!   t1: smoking, default (regression-based V)         — same as baseline
*!   t2: smoking, customV (bypass V optimization)
*!   t3: smoking, nested + xperiod
*!   t4: smoking, keep() saves a results dataset
*!   t5: germany, default (West Germany reunification, AJPS 2014)
*!
*! How to run from repo root:
*!   /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do dev/03_integration_tests.do
*!
*! Outputs:
*!   dev/integration_outputs.txt   key matrices for each test
*!   dev/integration_tests.log     full Stata log

clear all
set more off
set seed 20260429

adopath ++ "`c(pwd)'"

log using "dev/integration_tests.log", replace text

file open out using "dev/integration_outputs.txt", write replace text
file write out "Synth Stata integration tests — current source" _n _n

capture program drop dump_results
program dump_results
  args label
  file write out "==== `label' ====" _n
  file write out "RMSPE:" _n
  mat L = e(RMSPE)
  forv i = 1/`=rowsof(L)' {
    file write out %18.8f (L[`i',1]) _n
  }
  file write out "max V diag (proxy for V):" _n
  mat V = e(V_matrix)
  scalar mxV = .
  forv i = 1/`=rowsof(V)' {
    if (V[`i',`i'] > mxV | mxV >= .) scalar mxV = V[`i',`i']
  }
  file write out %18.8f (mxV) _n
  file write out "sum W weights:" _n
  mat W = e(W_weights)
  scalar sw = 0
  forv i = 1/`=rowsof(W)' {
    scalar sw = sw + W[`i',2]
  }
  file write out %18.8f (sw) _n _n
end

* -------------------- t1: smoking default --------------------
display _newline as txt "=== t1: smoking default ==="
use "smoking.dta", clear
tsset state year
synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) ///
        cigsale(1980) cigsale(1975), trunit(3) trperiod(1989)
dump_results "t1 smoking default"

* -------------------- t2: smoking customV --------------------
display _newline as txt "=== t2: smoking customV ==="
use "smoking.dta", clear
tsset state year
synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) ///
        cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) ///
        customV(1 1 1 1 1 1 1)
dump_results "t2 smoking customV"

* -------------------- t3: smoking nested + xperiod --------------------
display _newline as txt "=== t3: smoking nested + xperiod ==="
use "smoking.dta", clear
tsset state year
synth cigsale beer lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), ///
        trunit(3) trperiod(1989) xperiod(1980(1)1988) nested
dump_results "t3 smoking nested xperiod"

* -------------------- t4: smoking keep() --------------------
display _newline as txt "=== t4: smoking keep() ==="
use "smoking.dta", clear
tsset state year
tempfile saved_synth
synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) ///
        cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) ///
        keep("`saved_synth'") replace
dump_results "t4 smoking keep"
* sanity check the saved file exists and has expected vars
preserve
use "`saved_synth'", clear
file write out "t4 saved-file vars: " _n
foreach v of varlist _all {
  file write out "  `v'" _n
}
file write out _n
restore

* -------------------- t5: germany default --------------------
display _newline as txt "=== t5: germany default ==="
use "germany.dta", clear
tsset country year
synth gdppc trade(1981(1)1989) inflation(1981(1)1989) industry(1971(1)1980) ///
        schooling(1980&1985) invrate(1980&1985) gdppc(1960) gdppc(1970) gdppc(1980), ///
        trunit(8) trperiod(1990)
dump_results "t5 germany default"

file close out
log close

display "Wrote dev/integration_outputs.txt and dev/integration_tests.log"
