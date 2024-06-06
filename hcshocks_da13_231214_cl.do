sysdir set PLUS "H:\Documents\ado\plus"
sysdir set PERSONAL "H:\Documents\ado\personal"
cd "H:\Documents\HC shocks"

cap log close 
log using "Output\results.log", replace

// Note: DV regression in data cleaning do-file "hcshocks_d12_230929_cl"

* Any disaster + number of disasters 
use "Data\hcshocks12pd_ym", clear
sum pd_dpnx_i
sum dv_gp_i
xtset ppn t

tab pd_dpnx_i pd_dpnx_n

cap erase "Output\lastXXmosfe.csv"
foreach s of varlist mgr mmgr200 {
	est drop _all
	preserve 
	keep if `s' == 1
	local u i n 
	foreach l of local u {
		xtreg pd_dpnx_i ///
		disl13m_`l' disl46m_`l' disl79m_`l' ///
		disl1012m_`l' disl1315m_`l' disl1618m_`l' ///
		i.t, cluster(cofo) fe
		sum pd_dpnx_i if e(sample) == 1 
		estadd scalar mean = r(mean)
		est sto `s'dis`l'
	}
	restore
	esttab _all using "Output\lastXXmosfe.csv", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum keep(*dis*) append
	
	esttab _all using "Output\lastXXmos_`s'fe.tex", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(4 ) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
}

* BASELINE: Major disasters 
use "Data\hcshocks12pd_ym", clear
sum pd_dpnx_i
sum dv_gp_i

cap erase "Output\pvalallfe.csv"
cap erase "Output\tstatfe.csv"

foreach s of varlist mgr mmgr200 {
	preserve 
	keep if `s' == 1
	local u dir pp
	foreach l of local u {
	est drop _all
		foreach k of numlist 1 5 10 {
			cap drop dis`l'l*m_i
			rename dis`l'`k'l*m_i dis`l'l*m_i
			xtreg pd_dpnx_i ///
			dis`l'l13m_i dis`l'l46m_i dis`l'l79m_i ///
			dis`l'l1012m_i dis`l'l1315m_i dis`l'l1618m_i ///
			i.t, cluster(cofo) fe
			sum pd_dpnx_i if e(sample) == 1 
			estadd scalar mean = r(mean)
			est sto `s'`l'`k'
		}
	esttab _all using "Output\lastXXmosfe.csv", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs note nonum keep(*dis*) append
	
	esttab _all using "Output\lastXXmos_`s'_`l'fe.tex", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(4 ) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
	}
	restore
}

* All indicators in one regression 
use "Data\hcshocks12pd_ym", clear

sum disdir1l13m_i disdir5l13m_i disdir10l13m_i 

local u dir pp
foreach l of local u {
	foreach k of numlist 13 46 79 1012 1315 1618 {
		gen dis`l'110l`k'm_i = dis`l'1l`k'm_i ==1 & dis`l'10l`k'm_i == 0 
		gen dis`l'l1l`k'm_i = disl`k'm_i ==1 & dis`l'1l`k'm_i == 0 
	}
}

sum disl13m_i disdirl1l13m_i disdir110l13m_i disdir10l13m_i

local u disdir
foreach l of local u {
	local v l1 110 10
	foreach k of local v {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			label var `l'`k'l`lb'`ub'm_i "`lb'-`ub' months ago"
		}
	}
}

est drop _all
foreach s of varlist mmgr200 mgr  {
	preserve 
	keep if `s' == 1
	local u dir //pp
	foreach l of local u {
		xtreg pd_dpnx_i ///
		dis`l'l1l13m_i dis`l'l1l46m_i dis`l'l1l79m_i dis`l'l1l1012m_i ///
		dis`l'110l13m_i dis`l'110l46m_i dis`l'110l79m_i dis`l'110l1012m_i ///
		dis`l'10l13m_i dis`l'10l46m_i dis`l'10l79m_i dis`l'10l1012m_i ///
		i.t, cluster(cofo) fe
		sum pd_dpnx_i if e(sample) == 1 
		estadd scalar mean = r(mean)
		est sto `s'`l'
	}
	restore
}

esttab mmgr200dir mgrdir  using "Output\lastXXmo_dirfe_all.tex", ///
b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
scalars("mean Mean (dep var)" ) sfmt(4 ) ///
fragment booktabs ///
nogap mti noobs nonote nonum label keep(*dis*) replace

esttab _all using "Output\lastXXmosfe_all.csv", ///
b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
nogap mti noobs note nonum keep(*dis*) append

* Extensive vs intensive marging (>= 1 prescription vs # of prescriptions)
use "Data\hcshocks12pd_ym", clear

sum pd_dpnx_*
tab pd_dpnx_n 
tab pd_dpnx_n if pd_dpnx_i == 1

xtset ppn t
foreach s of varlist mgr mmgr200 {
	est drop _all
	preserve 
	keep if `s' == 1
	local u i n 
	foreach l of local u {
		xtreg pd_dpnx_`l' ///
		disdir10l13m_i disdir10l46m_i disdir10l79m_i ///
		disdir10l1012m_i disdir10l1315m_i disdir10l1618m_i ///
		i.t, cluster(cofo) fe
		sum pd_dpnx_`l' if e(sample) == 1 
		estadd scalar mean = r(mean)
		est sto `s'pd`l'
	}
	restore
	esttab _all using "Output\lastXXmosfe.csv", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum keep(*dis*) append
	
	esttab _all using "Output\pdin_`s'fe.tex", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(4 ) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
}

* Expenditures on drugs and doctor visits 
use "Data\hcshocks12pd_ym", clear
merge 1:1 ppn year month using "Data\pd_0514_mo", keepusing(exp_pbs) keep(match) nogenerate
merge 1:1 ppn year month using "Data\dv_0514_mo", keepusing(exp_mbs) keep(match) nogenerate
gen exp = exp_pbs + exp_mbs
order exp_pbs exp_mbs, after(exp)
sum exp*

// deflate using CPI
preserve 
import excel using "Data\640106", sheet(Data1) cellrange(A11:B313) clear
gen quart = quarter(A)
gen year = year(A)
rename B cpi
drop A
save "Data\cpi_au", replace
restore

rename qrt quart
merge m:1 year quart using "Data\cpi_au", keep(match) nogenerate

local v exp exp_pbs exp_mbs
foreach y of local v {
	cap drop `y'df
	gen `y'df = `y'*100/cpi
}
sum exp*

// regress expenditures on pd_dpnx_i
xtreg expdf pd_dpnx_i i.t, cluster(cofo) fe
xtreg exp_pbsdf pd_dpnx_i i.t, cluster(cofo) fe
xtreg exp_mbsdf pd_dpnx_i i.t, cluster(cofo) fe

// log? - No, too many observations with 0 exp in given month, log (exp) don't look normal either
sum exp* if exp <= 0 
local v exp exp_pbs exp_mbs
foreach y of local v {
	cap drop temp
	cap drop ln`y'
	gen temp = `y'
	replace temp = 0.01 if `y' <=0
	gen ln`y' = log(temp)
	drop temp
	histogram `y' if inrange(`y', 1, 1000), bins(100) normal name(`y', replace)
}

est drop _all
foreach s of varlist mgr mmgr200 { //
	preserve
	keep if `s' == 1
	local u dir // pp
	foreach l of local u {
		foreach k of numlist 10 {
			local v exp exp_pbs exp_mbs
			foreach y of local v {
				xtreg `y'df ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t, cluster(cofo) fe
				sum `y'df
				estadd scalar mean = r(mean)
				est sto `s'`y'df
			}
		}
	}
	restore
}

cap erase "Output\exp.csv"
foreach s of varlist mgr mmgr200 { //
	esttab `s'*df using "Output\exp.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum label keep(*dis*) append
}

// Indicator for greater than median expenditures
local v exp exp_pbs exp_mbs
foreach y of local v {
	sum `y'df, detail
	gen `y'df_gtm = `y' > r(p50) if !missing(`y')
}
sum exp*_gtm

foreach s of varlist mgr mmgr200 { //
	preserve
	keep if `s' == 1
	local u dir // pp
	foreach l of local u {
		foreach k of numlist 10 {
			local v exp exp_pbs exp_mbs
			foreach y of local v {
				xtreg `y'df_gtm ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t, cluster(cofo) fe
				sum `y'df_gtm
				estadd scalar mean = r(mean)
				est sto `s'`y'df_gtm
			}
		}
	}
	restore
}

foreach s of varlist mgr mmgr200  { 
	esttab `s'*df_gtm using "Output\exp.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum label keep(*dis*) append
}

foreach s of varlist mgr mmgr200  { 
	esttab `s'expdf `s'expdf_gtm using "Output\exp_`s'.tex", ///
	b(3) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(2) ///
	fragment booktabs ///
	nogap mti noobs nonote nonum label keep(*dis*) replace
}

* Specific MH issues + history of MH issues + history of disasters
* Anxiety, Depression
use "Data\hcshocks12pd_ym", clear
est drop _all
xtset ppn t
foreach s of varlist mgr mmgr200 { //mmgr200
	preserve
	keep if `s' == 1
	local u dir // pp
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dep_i pd_anx_i dv_mhp_i
			foreach y of local v {
				xtreg `y' ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t, cluster(cofo) fe
				sum `y'
				estadd scalar mean = r(mean)
				est sto `s'`y'
			}
		}
	}
	restore
}

* History of illness
use "Data\hcshocks12pd_ym", clear
tab pd_dpnxl1924m_i 
tab pd_dpnxl1318m_i if pd_dpnxl1924m_i == 1
tab pd_dpnx_i if pd_dpnxl1924m_i == 1 & pd_dpnxl1318m_i == 0

xtset ppn t
foreach s of varlist mgr mmgr200  { 
	preserve
	keep if `s' == 1
	local u dir 
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dpnx 
			foreach y of local v {
			* Those with disease 19/24 months or 13/18 months before 
				xtreg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t ///
				if `y'l1924m_i == 1 | `y'l1318m_i == 1, cluster(cofo) fe 
				sum `y'_i if e(sample) == 1 
				estadd scalar mean = r(mean)
				est sto `s'hmh21
			* Those with no disease 19/24 months before and no disease 13/18 months before 
				xtreg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t ///
				if `y'l1924m_i == 0 & `y'l1318m_i == 0, cluster(cofo) fe 
				sum `y'_i if e(sample) == 1 
				estadd scalar mean = r(mean)
				est sto `s'hmh20
			}
		}
	}
	restore
}

* Heterogeneity by history of disasters
use "Data\hcshocks12pd_ym", clear
// Those who experienced disaster 13-36 months before
merge m:1 iso year month using "Data\temp\temp_dis4.dta", keepusing(disdir*l1324* disdir*l2536*)
drop if _merge == 2

preserve
keep if (disdir10l13m_i==1 | disdir10l46m_i==1 | disdir10l79m_i==1 | disdir10l1012m_i ==1) & mmgr200 == 1 
tab name45up
sum  disdir1l1324m_i disdir1l2536m_i disdir5l1324m_i disdir5l2536m_i disdir10l1324m_i disdir10l2536m_i

tab name45up if disdir1l1324m_i == 1 |  disdir1l2536m_i == 1
tab name45up if disdir1l1324m_i == 0 &  disdir1l2536m_i == 0
restore

xtset ppn t
foreach s of varlist mgr mmgr200  {
	preserve
	keep if `s' == 1
	local u dir // pp
	foreach l of local u {
		foreach k of numlist 10 {
			xtreg pd_dpnx_i ///
			dis`l'`k'l13m_i dis`l'`k'l46m_i ///
			dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
			i.t ///
			if disdir1l1324m_i == 1 |  disdir1l2536m_i == 1, ///
			cluster(cofo) fe 
			sum pd_dpnx_i if e(sample) == 1 
			estadd scalar mean = r(mean)
			est sto `s'hdis1
			
			xtreg pd_dpnx_i ///
			dis`l'`k'l13m_i dis`l'`k'l46m_i ///
			dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
			i.t ///
			if disdir1l1324m_i == 0 &  disdir1l2536m_i == 0, ///
			cluster(cofo) fe 
			sum  pd_dpnx_i if e(sample) == 1 
			estadd scalar mean = r(mean)
			est sto `s'hdis0
		}
	}
	restore
}

cap erase "Output\othmhfe.csv"
foreach s of varlist mgr mmgr200 { 
	esttab `s'* using "Output\othmhfe2.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum label keep(*dis*) append

	esttab `s'pd* `s'h* using "Output\othmh2_`s'fe.tex", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(4 ) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
}


* HETEROGENEITY 
use "Data\hcshocks12pd_ym", clear
drop dispp*

sum ppn yrarr age distkm hcgdp hcpop 
sum ppn yrarr age distkm hcgdp hcpop if mmgr200 == 1

* Connectedness
* Years since arrival - define separately for mgr and mmgr200 
gen yrsarr = year- yrarr
sum yrsarr, detail 
unique ppn if yrsarr < 0
//browse yrarr year if yrsarr < 0
replace yrsarr = . if yrsarr <= 0 
sum yrsarr
bysort mmgr200: sum yrsarr

* Distance
// Mean distance among countries w/ major dis = 6512 (from Excel file)
replace distkm = distkm / 1000
sum distkm, detail
gen distkm_dm = distkm - 6.512
sum distkm_dm, detail 
label var distkm_dm "Distance from HC 1000km - 6.512"

* GDP in 2003 (before any major disaster in analysis period)
// Mean GDP among countries w/ major dis = 8472 (from Excel file)
drop hcgdp
rename year temp
gen year = 2003
merge m:1 iso year using "Data\hcgdp", keepusing(hcgdp)
drop if _merge ==2 
drop _merge
drop year  
rename temp year
replace hcgdp = hcgdp / 1000
label var hcgdp "HC GDP in 2003, k2010$"
sum hcgdp, detail
gen hcgdp_dm = hcgdp - 8.472
label var hcgdp_dm "HC GDP in 2003, k2010$- 8.472"

* Social capital
preserve 
use "Data\45andup_1.dta",clear 
sum Soc*
rename Soc* soc*
sum soc*
factor soc*
rotate
predict sccptf
keep ppn sccptf
sum sccptf, detail
save "Data\temp\sccpt", replace
restore 

merge m:1 ppn using "Data\temp\sccpt", keepusing()
drop if _merge ==2 
drop _merge 
sum sccptf, detail

* Networks
drop hcpop*
rename name45up name
local u 06 //11 16 
foreach k of local u { 
	merge m:1 name pcode using "Data\hcpop_pcode_`k'.dta"
	di "20`k'"
	unique pcode if _merge ==1 
	tab pcode if _merge ==1
	unique pcode if _merge ==2
	tab pcode if _merge ==2
	drop if _merge == 2
	drop _merge
}
sum hcpop*

* Create network variable
* Antidepressant use by postcode and CoB
bysort pcode cofo: egen pd_dpnx_pccb = mean(pd_dpnx_i)
sum pd_dpnx_pccb
* Network quality = (HC pop density in pcode)/(HC pop density in NSW) * Antidepressant use in postcode
gen ntw = (hcpop06/hcpoptot06) * pd_dpnx_pccb
//sort ppn t
//browse ppn t pd_dpnx_i pcode name if pd_dpnx_pccb == 1
* Standardize
sum ntw
replace ntw = (ntw - r(mean))/r(sd)

* % HC pop in postcode
replace hcpop06 = hcpop06 * 100

sum hcpop06 ntw
unique pcode

* Regressions
cap set matsize 10000
est drop _all

xtset ppn t

* Continuous variables
foreach s of varlist mgr mmgr200 {
	cap erase "Output\het_`s'fe.csv"
	
	preserve 
	keep if `s' == 1
	
	sum yrsarr 
	gen yrsarr_dm = yrsarr - r(mean)

	foreach l of varlist distkm_dm yrsarr_dm hcgdp_dm sccptf hcpop06 ntw {
		di "`l'"
		gen temp = `l'
		sum temp, detail
		gen temp_gtm = temp > r(p50) if !missing(temp)

		xtreg pd_dpnx_i ///
		(disdir10l13m_i disdir10l46m_i ///
		disdir10l79m_i disdir10l1012m_i)##i.temp_gtm ///
		i.t, cluster(cofo) fe
		sum pd_dpnx_i if e(sample)
		estadd scalar mean = r(mean)
		est sto `s'`l'd_1
		
		xtreg pd_dpnx_i ///
		(disdir10l13m_i disdir10l46m_i ///
		disdir10l79m_i disdir10l1012m_i)##c.temp ///
		i.t, cluster(cofo) fe
		sum pd_dpnx_i if e(sample)
		estadd scalar mean = r(mean)
		est sto `s'`l'c_1

		drop temp*
	}
	restore
}

foreach s of varlist mgr mmgr200 {
	esttab `s'*d_* using "Output\het_`s'fe.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum label keep(*dis*) drop(*0.*) replace

	esttab `s'*c_* using "Output\het_`s'fe.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum label keep(*dis*) drop(*0.*) append

	est drop `s'hcgdp_dm* `s'ntw*
	esttab `s'*c_* using "Output\het_`s'fe.tex", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)") sfmt(4) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) drop(*0.*) replace
}

* Categorical variables
use "Data\hcshocks12pd_ym", clear
merge m:1 ppn using  "Data\45andup_1.dta", keepusing(mrdprtn)
drop if _merge == 2
drop _merge 

drop dispp*

sum age, detail
sum age if mmgr200 == 1, detail
gen age_gt70 = age > 70 if !missing(age)

gen single = 1 - mrdprtn 
sum single mrdprtn

foreach k of varlist male age_gt70 single educ_univ ///
	income_lt20k seifa_bqnt cofo_r3  {
	bysort disdir10l1012m_i: tab `k' if mmgr200 == 1, nol
}

xtset ppn t

foreach s of varlist mgr mmgr200 {
	preserve 
	keep if `s' == 1
	est drop _all
	foreach l of varlist male age_gt70 single educ_univ ///
	income_lt20k seifa_bqnt {
		di "`l'"
		gen temp = `l'
		xtreg pd_dpnx_i ///
		(disdir10l13m_i disdir10l46m_i ///
		disdir10l79m_i disdir10l1012m_i)##i.temp ///
		i.t, cluster(cofo) fe
		sum pd_dpnx_i if e(sample)
		estadd scalar mean = r(mean)
		est sto `s'`l'
		drop temp*
	}
	esttab _all using "Output\het_`s'fe.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum label keep(*dis*) drop(*0.*) append
	
	esttab _all using "Output\hetdem_`s'fe.tex", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)") sfmt(4) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) drop(*0.*) replace
	
	est drop `s'income_lt20k `s'seifa_bqnt
	esttab _all using "Output\hetdemr_`s'fe.tex", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)") sfmt(4) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) drop(*0.*) replace
	restore
}

foreach s of varlist mgr mmgr200 {
	preserve 
	keep if `s' == 1
	est drop _all
	foreach l of varlist cofo_r3 {
		xtreg pd_dpnx_i ///
		(disdir10l13m_i disdir10l46m_i ///
		disdir10l79m_i disdir10l1012m_i)##i.`l' ///
		i.t, cluster(cofo) fe
		est sto `s'`l'
	}
	esttab _all using "Output\het_`s'fe.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	nogap mti obs nonote nonum label keep(*dis*) drop(*0.*) append
	restore
}


* Alternative specifications
use "Data\hcshocks12pd_ym", clear
keep ppn t year month cofo pd_dpnx_i disdir10l* mgr mmgr200 diedhy diedmbsy

est drop _all
* Individual FE - Baseline
xtset ppn t
foreach s of varlist mgr mmgr200 { // {
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dpnx  
			foreach y of local v {
				xtreg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t, cluster(cofo) fe
				sum `y'_i if e(sample)
				estadd scalar mean = r(mean)
				est sto `s'indfe
			}
		}
	}
	restore
}

* Balanced panel
cap drop temp*
gen temp = !missing(pd_dpnx_i) 
tab temp
bysort ppn (t): egen temp2 = sum(temp)
bysort ppn (t): gen temp3 = _n 
tab temp2 if temp ==1
tab temp2 if temp3== 1 

foreach s of varlist mgr mmgr200 { 
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dpnx  
			foreach y of local v {
				xtreg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t if temp2 == 110, fe cluster(cofo)
				sum `y'_i if e(sample)
				estadd scalar mean = r(mean)
				est sto `s'blpn
			}
		}
	}
	restore
}
drop temp*

* Country FE
foreach s of varlist mgr mmgr200 { 
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dpnx 
			foreach y of local v {
				reg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.cofo i.t, cluster(cofo)
				sum `y'_i if e(sample)
				estadd scalar mean = r(mean)
				est sto `s'cobfe
			}
		}
	}
	restore
}

* Country-year and country-month effects 
foreach s of varlist mgr mmgr200 { 
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dpnx 
			foreach y of local v {
				reg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.cofo##i.year i.cofo##i.month, ///
				cluster(cofo) 
				sum `y'_i if e(sample)
				estadd scalar mean = r(mean)
				est sto `s'cofoym
			}
		}
	}
	restore
}

* + country-specific trend (annual)
gen year2005 = year - 2005

set matsize 10000

foreach s of varlist mgr mmgr200 { //mmgr200 {
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dpnx  
			foreach y of local v {
				reg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.cofo i.t i.cofo#c.year2005, ///
				cluster(cofo) 
				sum `y'_i if e(sample)
				estadd scalar mean = r(mean)
				est sto `s'cofot
			}
		}
	}
	restore
}

* Keep only migrants who experienced a major disaster
foreach s of varlist mgr mmgr200 {
	preserve 
	keep if `s' == 1
	local u dir 
	foreach l of local u {
		foreach k of numlist 10 {
			cap drop temp*
			local v 13 46 79 1012 
			foreach n of local v {
				bysort ppn: egen temp`n' = max(dis`l'`k'l`n'm_i)
			}
			egen temp = rowmax(temp13 temp46 temp79 temp1012)
			keep if temp > 0 & !missing(temp) 
			xtreg pd_dpnx_i ///
			dis`l'`k'l13m_i dis`l'`k'l46m_i dis`l'`k'l79m_i ///
			dis`l'`k'l1012m_i ///
			i.t, cluster(cofo) fe
			sum pd_dpnx_i if e(sample) 
			estadd scalar mean = r(mean)
			est sto `s'expdis1
		}
	}
	restore
}

* Control for history of mental illness 
use "Data\hcshocks12pd_ym", clear
tab pd_dpnxl1924m_i pd_dpnxl1318m_i, cell
gen pd_dpnxl1324m_i = pd_dpnxl1924m_i == 1 | pd_dpnxl1318m_i == 1 if !missing(pd_dpnxl1924m_i, pd_dpnxl1318m_i)
sum pd_dpnxl1324m_i

xtset ppn t

foreach s of varlist mgr mmgr200  { 
	preserve
	keep if `s' == 1
	local u dir // pp
	foreach l of local u {
		foreach k of numlist 10 {
			local v pd_dpnx 
			foreach y of local v {
				xtreg `y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i pd_dpnxl1324m_i ///
				i.t, cluster(cofo) fe 
				sum `y'_i if e(sample) == 1 
				estadd scalar mean = r(mean)
				est sto `s'cntrlmh
			}
		}
	}
	restore
}

esttab *cntrlmh using "Output\cntrlpmhfe2.csv", ///
b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
nogap mti noobs nonote nonum label keep(*dis*) replace

esttab *cntrlmh using "Output\cntrlpmhfe2.tex", ///
b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
scalars("mean Mean (dep var)" ) sfmt(4 ) ///
fragment booktabs ///
nogap nomti noobs nonote nonum label keep(*dis*) replace


cap erase "Output\altspecfe.csv"
foreach s of varlist mgr mmgr200 {
	esttab `s'* using "Output\altspecfe.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum keep(*dis*) append

	esttab `s'indfe `s'blpn `s'cobfe `s'cofot `s'cofoym using "Output\altspec1_`s'fe.tex", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(4 ) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
	
	esttab `s'indfe `s'xdd `s'expdis1 `s'cntrlmh using "Output\altspec2_`s'fe.tex", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(4 ) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
}


* OTHER CONDITIONS 
use "Data\hcshocks12pd_ym", clear

gen pd_omho_i = pd_mh_i
replace pd_omho_i = 0 if pd_anx_i == 1 | pd_dep_i == 1

sum pd_psch_i pd_omho_i if pd_anx_i == 0 & pd_dep_i == 0

xtset ppn t

local u disdir // 
foreach l of local u {
	foreach k of numlist 10 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			label var `l'`k'l`lb'`ub'm_i "`lb'-`ub'"
		}
	}
}

foreach s of varlist mgr mmgr200  { 
	preserve
	keep if `s' == 1
	local u dir 
	foreach l of local u {
		foreach k of numlist 10 {
			est drop _all
			local v psch diab hrt asth
			foreach y of local v {
				xtreg pd_`y'_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i ///
				dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
				i.t, cluster(cofo) fe
				sum pd_`y'_i 
				estadd scalar mean = r(mean)
				est sto `y'`l'`k'
				coefplot `y'`l'`k', keep(disdir`k'l13m_i disdir`k'l46m_i 				disdir`k'l79m_i disdir`k'l1012m_i) vertical 			graphregion(color(white)) yline(0) xtitle("Months after disaster") name(gr`s'`y', replace) omitted scheme(sj)
				graph save "Output\gr`s'`y'", replace
			}
			esttab _all using "Output\othdis2_`s'fe.csv", ///
			b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
			scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
			nogap mti obs nonote nonum label keep(*dis*) replace 
			esttab _all using "Output\othdis2_`s'fe.tex", ///
			b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
			fragment booktabs ///
			scalars("mean Mean (dep var)") sfmt(4) ///
			nogap nomti noobs nonote nonum label keep(*dis*) replace
		}
	}
	restore
}

// Edit graph titles manually
graph combine grmmgr200psch grmmgr200diab grmmgr200hrt grmmgr200asth
graph save "Output\grmmgr200oc.gph", replace
graph export "Output\grmmgr200oc.pdf", replace
graph export "Output\grmmgr200oc.tif", replace
graph export "Output\grmmgr200oc.eps", replace


* Terrorist acts 
do "Data\hcschocks_ta_231124_cl"

use "Data\hcshocks12pd_ym", clear
merge m:1 iso year month using "Data\temp\temp_terra4.dta", //keepusing(*killwoundnt*)
tab iso if _merge == 2
drop if _merge == 2
drop _merge

fsum *killwoundnt* if mmgr200 ==1 , f(10.4) //dis*

drop dis*

xtset ppn t
cap erase "Output\tafe.csv"

foreach s of varlist mmgr200 mgr {
	preserve 
	keep if `s' == 1
	local u killwoundnt
	foreach l of local u {
	est drop _all
		foreach k of numlist 1 5 { //
			cap drop geq`l'ppl*m_i
			rename geq`k'pp`l'l*m_i geq`l'ppl*m_i
			xtreg pd_dpnx_i ///
			geq`l'ppl13m_i geq`l'ppl46m_i geq`l'ppl79m_i ///
			geq`l'ppl1012m_i geq`l'ppl1315m_i geq`l'ppl1618m_i ///
			i.t, cluster(cofo) fe
			sum pd_dpnx_i if e(sample)
			estadd scalar mean = r(mean)
			est sto `s'`l'pp`k'
		}
	esttab _all using "Output\tafe.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti obs nonote nonum keep(geq*) append
	
	esttab _all using "Output\ta_`s'_`l'geqppfe.tex", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)") sfmt(4) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(geq*) replace
	}
	restore
}

foreach s of varlist mmgr200 mgr { //
	preserve 
	keep if `s' == 1
	local u killnt killwoundnt // 
	foreach l of local u {
	est drop _all
		foreach k of numlist 1 10 100  {
			cap drop geq`l'l*m_i
			rename geq`k'`l'l*m_i geq`l'l*m_i
			xtreg pd_dpnx_i ///
			geq`l'l13m_i geq`l'l46m_i geq`l'l79m_i ///
			geq`l'l1012m_i geq`l'l1315m_i geq`l'l1618m_i ///
			i.t, cluster(cofo) fe
			sum pd_dpnx_i if e(sample)
			estadd scalar mean = r(mean)
			est sto `s'`l'`k'
		}
	esttab _all using "Output\tafe.csv", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti obs nonote nonum keep(geq*) append
	
	esttab _all using "Output\ta_`s'_`l'geqfe.tex", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)") sfmt(4) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(geq*) replace
	}
	restore
}

foreach s of varlist mmgr200 {
	preserve 
	keep if `s' == 1
	local u  killwoundnt
	foreach l of local u {
		foreach k of numlist 1 5  {
			di ">=`k' / 100,000"
			tab name45up if geq`k'pp`l'l13m_i  == 1 | geq`k'pp`l'l46m_i == 1 | geq`k'pp`l'l79m_i == 1 | ///
			geq`k'pp`l'l1012m_i == 1 | geq`k'pp`l'l1315m_i == 1 | geq`k'pp`l'l1618m_i== 1 
		}
		foreach k of numlist 1 10 100  {
		di ">=`k'"
		tab name45up if geq`k'`l'l13m_i  == 1 | geq`k'`l'l46m_i == 1 | geq`k'`l'l79m_i == 1 | ///
		geq`k'`l'l1012m_i == 1 | geq`k'`l'l1315m_i == 1 | geq`k'`l'l1618m_i== 1 
		}		
	}
	restore
}


* MACRO VARIABLES
use "Data\hcshocks12pd_ym", clear
drop dis*
drop hcgdp
local u gdp gdpnom cpi
foreach k of local u {
	preserve
	use "Data\hc`k'.dta", clear
	cap encode iso, gen(isonum)
	xtset isonum year
	cap gen hc`k'l = L.hc`k'
	save "Data\hc`k'.dta", replace
	restore
	merge m:1 iso year using "Data\hc`k'.dta"
	tab iso if _merge == 2
	drop if _merge == 2
	drop _merge
}

sum hc*
rename hcgdp hcgdpreal
rename hcgdpl hcgdpreall
sum year month if missing(hcgdpnom)
tab name45up if missing(hcgdpnom)

cap drop hc*lg*
foreach k of varlist hcgdpreal hcgdpreall hcgdpnom hcgdpnoml {
		gen `k'lg = log(`k')
}
sum hcgdp*
rename hcgdprealllg hcgdpreallgl
rename hcgdpnomllg hcgdpnomlgl

xtset ppn t
 
cap erase "Output\macrovarsfe.csv"
foreach s of varlist mgr mmgr200 {
	est drop _all
	preserve 
	keep if `s' == 1
	foreach k of varlist hcgdpreallg hcgdpnomlg hccpi {
		di "`s' `k'"
		xtreg pd_dpnx_i `k' `k'l i.t, cluster(cofo) fe
		sum pd_dpnx_i if e(sample)
		estadd scalar mean = r(mean)
		est sto `s'`k'
	}
	esttab _all using "Output\macrovarsfe.csv", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti obs nonote nonum keep(hc*) append
	
	esttab _all using "Output\macrovars_`s'_fe.tex", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" ) sfmt(4 ) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(hc*) replace

	restore
}


* Anticipation effects
use "Data\hcshocks12pd_ym", clear
merge m:1 iso year month using "Data\temp\temp_disf.dta", keepusing(disdir1n* disdir5n* disdir10n*)
drop if _merge == 2
keep ppn t cofo iso mgr mmgr200 pd_dpnx_i disdir*
xtset ppn t
save "Data\temp\esa", replace

cap erase "Output\anticipfe.csv"
foreach s of varlist mgr mmgr200 {
	preserve 
	keep if `s' == 1
	local u dir 
	foreach l of local u {
	est drop _all
		foreach k of numlis 1 5 10 {
			di "`s' `l'`k'"
			cap drop dis`l'l*m_i
			rename dis`l'`k'l*m_i dis`l'l*m_i
			cap drop dis`l'n*m_i
			rename dis`l'`k'n*m_i dis`l'n*m_i
			cap drop dis`l'_i
			rename dis`l'`k'_i dis`l'_i

			xtreg pd_dpnx_i ///
			dis`l'n1012m_i dis`l'n79m_i dis`l'n46m_i ///
			dis`l'n13m_i   ///
			dis`l'_i ///
			dis`l'l13m_i dis`l'l46m_i dis`l'l79m_i ///
			dis`l'l1012m_i ///
			i.t, cluster(cofo) fe
			sum pd_dpnx_i if e(sample)
			estadd scalar mean = r(mean)
			est sto `s'`l'`k'
			
			coefplot `s'`l'`k', keep(dis`l'n1012m_i dis`l'n79m_i ///
			dis`l'n46m_i dis`l'n13m_i  dis`l'_i dis`l'l13m_i ///
			dis`l'l46m_i dis`l'l79m_i dis`l'l1012m_i) ///
			vertical graphregion(color(white)) yline(0) ///
			xlabel(1 "t-4" 2 "t-3" 3 "t-2" 4 "t-1" 5 "t" 6 "t+1" 7 "t+2" 8 "t+3" 9 "t+4")
			graph save "Output\esg`s'`l'`k'fe", replace

		}
	esttab _all using "Output\anticipfe.csv", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum keep(*dis*) append
	
	esttab _all using "Output\anticip_`s'fe.tex", ///
	b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)")  sfmt(4) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
	}
	restore
}

* An ES graph (- next 1-3 months)
keep if mmgr200 ==1 
xtreg pd_dpnx_i ///
disdir10n1012m_i disdir10n79m_i disdir10n46m_i ///
disdir10n13m_i  ///
disdir10_i ///
disdir10l13m_i disdir10l46m_i disdir10l79m_i ///
disdir10l1012m_i ///
i.t, cluster(cofo) fe
est save "Data\temp\temp", replace
est sto temp 
est restore temp 

matrix coef = J(1,9,.)
matrix CI = J(2,9,.)

local i 0
foreach m of varlist disdir10n1012m_i disdir10n79m_i disdir10n46m_i disdir10n13m_i disdir10_i disdir10l13m_i disdir10l46m_i disdir10l79m_i disdir10l1012m_i {
	local ++ i
	lincom _b[`m'] - _b[disdir10n13m_i]
	matrix coef[1,`i']=r(estimate)
	matrix CI[1,`i']=r(lb)\r(ub)
}
matrix list coef
matrix list CI

coefplot matrix(coef), ci(CI) vertical graphregion(color(white)) yline(0) xlabel(1 "t-4" 2 "t-3" 3 "t-2" 4 "t-1" 5 "t" 6 "t+1" 7 "t+2" 8 "t+3" 9 "t+4")
graph save "Output\esgmmgr200dir10difffe", replace


* Omit each country with disaster at a time - major migrant groups only
cap erase "Output\dropcfe.csv"
local gr mmgr200
foreach s of local gr {
	use "Data\hcshocks12pd_ym", clear
	keep if `s' == 1
	est drop _all
	local iso IDN LKA CHN CHL NZL PHL  
	foreach c of local iso {
		di "`s' `c'"
		preserve 
		drop if iso == "`c'"
		local u dir 
		foreach l of local u {
			foreach k of numlis 10 {
				xtreg pd_dpnx_i ///
				dis`l'`k'l13m_i dis`l'`k'l46m_i dis`l'`k'l79m_i ///
				dis`l'`k'l1012m_i ///
				i.t, cluster(cofo) fe
				sum pd_dpnx_i if e(sample)
				estadd scalar mean = r(mean)
				est sto `s'`c'`l'`k'
			}
		}
		restore 
	}
	esttab _all using "Output\dropcfe.csv", ///
	b(4) se  star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
	nogap mti noobs nonote nonum keep(*dis*) append 
	
	esttab _all using "Output\dropc_`s'fe.tex", ///
	b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
	scalars("mean Mean (dep var)") sfmt(4) ///
	fragment booktabs ///
	nogap nomti noobs nonote nonum label keep(*dis*) replace
}

* Heterogeneity by type of disaster: earthquakes vs tsunamis vs cyclones
use "Data\hcshocks12pd_ym", clear
merge m:1  iso year month using "Data\temp\temp_dis4.dta", keepusing(disgrmovdir* distsnmdir* dismeteodir10*)
drop if _merge == 2

cap erase "Output\dstype2fe.csv"
foreach s of varlist  mmgr200 { //mmgr200 {mgr
	preserve 
	keep if `s' == 1
	foreach k of numlist 10 {
		est drop _all
		local u grmov tsnm meteo // meteo = storm
		foreach l of local u {
			di "`s' `l'"
			cap drop disdir`k'l*m_i
			rename dis`l'dir`k'l*m_i disdir`k'l*m_i
			local v pd_dpnx // dv_gp 
			foreach y of local v { 
				xtreg `y'_i ///
				disdir`k'l13m_i disdir`k'l46m_i ///
				disdir`k'l79m_i disdir`k'l1012m_i ///
				i.t, cluster(cofo) fe
				est sto `l'
				coefplot `l', keep(disdir`k'l13m_i disdir`k'l46m_i ///
				disdir`k'l79m_i disdir`k'l1012m_i) vertical graphregion(color(white)) yline(0) xtitle("Months after disaster")
				graph save "Output\gr`s'`l'", replace
			}
		}
		esttab _all using "Output\dstype2fe.csv", ///
		b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
		nogap mti obs nonote nonum keep(*dis*) append
		
		esttab _all using "Output\dstype2_`s'fe.tex", ///
		b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
		fragment booktabs ///
		nogap nomti noobs nonote nonum label keep(*dis*) replace
	}
	restore
}

* Graph 
local u disgrmovdir distsnmdir dismeteodir 
foreach l of local u {
	foreach k of numlist 10 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			label var `l'`k'l`lb'`ub'm_i "`lb'-`ub'"
		}
	}
}

local u disgrmovdir distsnmdir dismeteodir // new
foreach l of local u {
	foreach k of numlist 10 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			label var `l'`k'l`lb'`ub'm_i "`lb'-`ub'"
		}
	}
}

foreach s of varlist mgr mmgr200 { 
	preserve 
	keep if `s' == 1
	foreach k of numlist 10 {
		est drop _all
		local u grmov tsnm meteo // meteo = storm
		foreach l of local u {
			di "`s' `l'"
			cap drop disdir`k'l*m_i
			rename dis`l'dir`k'l*m_i disdir`k'l*m_i
			local v pd_dpnx  
			foreach y of local v { 
				xtreg `y'_i ///
				disdir`k'l13m_i disdir`k'l46m_i ///
				disdir`k'l79m_i disdir`k'l1012m_i ///
				i.t, cluster(cofo) fe
				est sto `l'
				coefplot `l', keep(disdir`k'l13m_i disdir`k'l46m_i ///
				disdir`k'l79m_i disdir`k'l1012m_i) vertical graphregion(color(white)) yline(0) xtitle("Months after disaster") name(gr`s'`l', replace) omitted scheme(sj)
				graph save "Output\gr`s'`l'", replace
			}
		}
	}
	restore
}

graph combine grmmgr200grmov grmmgr200tsnm grmmgr200meteo
// Changed scheme to Stata journal (2nd)
graph save "Output\grmmgr200dt.gph", replace
graph export "Output\grmmgr200dt.pdf", replace
graph export "Output\grmmgr200dt.tif", replace
graph export "Output\grmmgr200dt.eps", replace

cap log close
log using "Output\dtype_countries_231110_new.log", replace
foreach s of varlist mgr mmgr200 {
	preserve
	keep if `s' == 1
	local u grmov tsnm meteo
	foreach l of local u {
		di "`s' `l'"
		tab name45up if ///
		dis`l'dir10l13m_i == 1 | dis`l'dir10l46m_i == 1 | ///
		dis`l'dir10l79m_i == 1 | dis`l'dir10l1012m_i == 1
		unique ppn if ///
		dis`l'dir10l13m_i == 1 | dis`l'dir10l46m_i == 1 | ///
		dis`l'dir10l79m_i == 1 | dis`l'dir10l1012m_i == 1
	}
	restore
}
log close


cap log close 
log using "Output\results.log", append

* INFERENCE - alternative methods 

* BASELINE
// save p-values and t-stats
use "Data\hcshocks12pd_ym", clear

tab name45up if mmgr200 ==1
xtreg pd_dpnx_i ///
disdir10l13m_i disdir10l46m_i disdir10l79m_i ///
disdir10l1012m_i ///
i.t if mmgr200 == 1, cluster(cofo) fe
// On average an individual is observed 93.8 times

cap erase "Output\pvalallfe.csv"
cap erase "Output\tstatfe.csv"

* Unbalanced panel
foreach s of varlist mgr mmgr200 {
	preserve 
	keep if `s' == 1
	local u dir 
	foreach l of local u {
		est drop _all
		foreach k of numlist 1 5 10 {
			cap drop dis`l'l*m_i
			rename dis`l'`k'l*m_i dis`l'l*m_i
			xtreg pd_dpnx_i ///
			dis`l'l13m_i dis`l'l46m_i dis`l'l79m_i ///
			dis`l'l1012m_i ///
			i.t, cluster(cofo) fe
			sum pd_dpnx_i if e(sample) == 1 
			estadd scalar mean = r(mean)
			est sto `s'`l'`k'
		}
		esttab _all using "Output\pvalallfe.csv", ///
		b(4) p(4) wide plain nopar nostar ///
		scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
		nogap mti noobs note nonum keep(*dis*) append

		esttab _all using "Output\tstatfe.csv", ///
		b(4) t(3) wide nopar plain nostar  ///
		scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
		nogap mti noobs note nonum keep(*dis*) append
	}
	restore
}

* Balanced panel
cap drop temp*
gen temp = !missing(pd_dpnx_i) 
tab temp
bysort ppn (t): egen temp2 = sum(temp)
bysort ppn (t): gen temp3 = _n 
tab temp2 if temp ==1
tab temp2 if temp3== 1 
keep if temp2 == 110

foreach s of varlist mgr mmgr200 { // {
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		est drop _all
		foreach k of numlist 1 5 10 {
			cap drop dis`l'l*m_i
			rename dis`l'`k'l*m_i dis`l'l*m_i
			xtreg pd_dpnx_i ///
			dis`l'l13m_i dis`l'l46m_i ///
			dis`l'l79m_i dis`l'l1012m_i ///
			i.t, fe cluster(cofo)
			sum pd_dpnx_i if e(sample)
			estadd scalar mean = r(mean)
			est sto `s'`l'`k'blpn
		}
		esttab _all using "Output\pvalallfe.csv", ///
		b(4) p(4) wide plain nopar nostar ///
		scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
		nogap mti noobs note nonum keep(*dis*) append

		esttab _all using "Output\tstatfe.csv", ///
		b(4) t(3) wide nopar plain nostar  ///
		scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
		nogap mti noobs note nonum keep(*dis*) append
	}
	restore
}


* Wild bootstrap
use "Data\hcshocks12pd_ym", clear

cap erase "Output\boottestfe.csv"

* Unbalanced panel
foreach s of varlist mmgr200 mgr  {
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		est drop _all
		foreach k of numlist 1 5 10 {
			di "`s'`l'`k'"
			cap drop dis`l'l*m_i
			rename dis`l'`k'l*m_i dis`l'l*m_i
			xtreg pd_dpnx_i ///
			dis`l'l13m_i dis`l'l46m_i dis`l'l79m_i ///
			dis`l'l1012m_i ///
			i.t, cluster(cofo) fe
			sum pd_dpnx_i if e(sample) == 1 
			estadd scalar mean = r(mean)
			boottest ///
			{dis`l'l13m_i} {dis`l'l46m_i} {dis`l'l79m_i} ///
			{dis`l'l1012m_i}, bootcluster(cofo) seed(123456) ///
			weight(webb) reps(999) nograph //cluster(cofo)
			forvalues j = 1/4 {
				estadd scalar pval`j' = r(p_`j')
			}
			est sto `s'`l'`k'
		}
		esttab _all using "Output\boottestfe.csv", ///
		b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
		scalars("mean Mean (dep var)" "N Sample size" ///
		pval1 pval2 pval3 pval4) sfmt(4 0 4 4 4 4) ///
		nogap mti noobs note nonum keep(*dis*) append
	}
	restore
}

* Balanced panel
cap drop temp*
gen temp = !missing(pd_dpnx_i) 
tab temp
bysort ppn (t): egen temp2 = sum(temp)
bysort ppn (t): gen temp3 = _n 
tab temp2 if temp ==1
tab temp2 if temp3== 1 
keep if temp2 == 110

foreach s of varlist mgr mmgr200 { // {
	preserve 
	keep if `s' == 1
	local u dir
	foreach l of local u {
		est drop _all
		foreach k of numlist 1 5 10 {
			di "`s'`l'`k'"
			cap drop dis`l'l*m_i
			rename dis`l'`k'l*m_i dis`l'l*m_i
			xtreg pd_dpnx_i ///
			dis`l'l13m_i dis`l'l46m_i ///
			dis`l'l79m_i dis`l'l1012m_i ///
			i.t , fe cluster(cofo)
			sum pd_dpnx_i if e(sample)
			estadd scalar mean = r(mean)
			boottest ///
			{dis`l'l13m_i} {dis`l'l46m_i} {dis`l'l79m_i} ///
			{dis`l'l1012m_i}, bootcluster(cofo) seed(123456) ///
			weight(webb) reps(999) nograph //cluster(cofo)
			forvalues j = 1/4 {
				estadd scalar pval`j' = r(p_`j')
			}
			est sto `s'`l'`k'blpn
		}
		esttab _all using "Output\boottestfe.csv", ///
		b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
		scalars("mean Mean (dep var)" "N Sample size" ///
		pval1 pval2 pval3 pval4) sfmt(4 0 4 4 4 4) ///
		nogap mti noobs note nonum keep(*dis*) append
		restore
	}
}

* Lehmer's rule 
//signficant if |t|>(ln(N))^0.5
// All migrants (ln(N))^0.5 = (ln(3881270))^0.5 = 3.8950832
// 30 largest migrant groups (ln(N))^0.5 = (ln(3464152))^0.5 = 3.8804611

log close


cap log close 
log using "Output\perttest.log", append

*** NEED TO FIRST ENTER COEFFICIENT ESTIMATES TO coeffe.xlsx file ***

* PERTURBATION TEST
/* Randomly assign whole disaster history and country of birth - 
by person, balanced sample */

local sample  mmgr200 //mgr
foreach s of local sample {
	use "Data\hcshocks12pd_ym", clear 
	xtset ppn
	
	* Balanced panel
	gen temp = !missing(pd_dpnx_i) 
	bysort ppn (t): egen temp2 = sum(temp)
	bysort ppn (t): gen temp3 = _n 
	tab temp2 if temp ==1
	tab temp2 if temp3== 1 
	keep if temp2 == 110
	drop temp*
	
	keep if `s' == 1
	sort ppn t 
	
	* Create new person id
	preserve 
	keep ppn
	bysort ppn: gen temp = _n
	keep if temp == 1
	gen newid = _n
	drop temp
	save "Data\temp\newid`s'.dta", replace 
	restore
		
	* Merge disaster and CoB file w/ new ID 
	preserve
	keep ppn t cofo disdir10l13m_i disdir10l46m_i ///
	disdir10l79m_i disdir10l1012m_i 
	merge m:1 ppn using "Data\temp\newid`s'.dta", 
	drop if _merge == 2
	drop _merge ppn 
	sum
	save  "Data\temp\discb`s'.dta", replace 
	restore
	
	* Base file
	keep ppn t pd_dpnx_i

	cap erase  "Output\pt2p_`s'fe.csv"
	cap erase  "Output\pt2s_`s'fe.csv"
		
	unique ppn
	scalar max = r(sum)
	
	set seed 123456
	forvalues j = 1/999 {
		di _newline "`s' iteration `j'"
		
		* Randomly draw id 
		preserve
		keep ppn 
		bysort ppn: gen temp = _n
		keep if temp == 1
		gen newid = ceil(max*uniform())
		//unique newid
		drop temp
		//sum 
		save "Data\temp\newid`s'`j'.dta", replace 
		restore
	
		merge m:1 ppn using "Data\temp\newid`s'`j'.dta", 
		drop if _merge == 2
		drop _merge  
		erase "Data\temp\newid`s'`j'.dta"
		
		* Assign disaster history and country 
		merge m:1 newid t using "Data\temp\discb`s'", 	
		//bysort _merge: sum newid
		drop if _merge == 2
		
		/*sum disdir10l13m_i disdir10l46m_i ///
		disdir10l79m_i disdir10l1012m_i t cofo pd_dpnx_i newid*/

		xtreg pd_dpnx_i ///
		disdir10l13m_i disdir10l46m_i ///
		disdir10l79m_i disdir10l1012m_i ///
		i.t, cluster(cofo) fe

		esttab . using "Output\pt2p_`s'fe.csv", ///
		b(4) se wide plain collabels(none) ///
		nogap nomti nonum drop() keep(*dis*) append 

		esttab . using "Output\pt2s_`s'fe.csv", ///
		b(4) se wide star(* 0.10 ** 0.05 *** 0.01) collabels(none) ///
		nogap nomti nonum drop() keep(*dis*) append 
		
		
		keep ppn t pd_dpnx_i
	}
}

* Tables & graphs
* Critical and p-values 
local fe 2p
foreach a of local fe {
	local ss mgr mmgr200
	foreach s of local ss { 

		cap erase "Output\cv`a'_`s'fe.csv"
		import delimited "Output\pt`a'_`s'fe.csv", clear

		gen temp = substr(v1, 1,6)
		gen temp3 = substr(v1, 10,.)

		keep if temp == "disdir"
		keep v2 temp3

		cap drop id
		gen id = .
		local l = 1
		local u = 4
		forvalues i = 1/999 {
			replace id = `i' if _n >= `l' & _n <= `u'
			local l = `l' + 4
			local u = `u' + 4
		}
			
		reshape wide v2, i(id) j(temp3) string
		rename v2* cv_*
		order id cv_13m_i cv_46m_i cv_79m_i cv_1012m_i
		gen temp = 1 
		
		preserve 
		import excel "Output\coeffe.xlsx", clear firstrow sheet(`s'`a') 
		save "Data\temp\coef`s'`a'", replace
		restore
		
		merge m:1 temp using "Data\temp\coef`s'`a'"
		drop _merge temp
		destring b_*, replace
		
		local v 13 46 79 1012 
		foreach k of local v {
		
			sum b_`k'
			scalar temp`k' = r(mean)
			histogram cv_`k', name(c_`k', replace) ///
			xtitle(Last `k' months) xline(`=temp`k'') nodraw ///
			saving(Output\hist_`s'_`a'_`k'fe, replace) ///
			graphregion(fcolor(white) lcolor(white)) scheme(s2mono) ///
			ylabel(, nogrid)
			
			est drop _all
			sum cv_`k', detail

			sort cv_`k'
			cap drop pct
			gen pct = _n
			est drop _all
			mean cv_`k' if pct == 5
			eststo c005 
			mean cv_`k' if pct == 995
			eststo c995 
			mean cv_`k' if pct == 25
			eststo c025 
			mean cv_`k' if pct == 975
			eststo c975 
			mean cv_`k' if pct == 50
			eststo c050 
			mean cv_`k' if pct == 950
			eststo c950 
			
			esttab _all using "Output\cv`a'_`s'fe.csv", ///
			b(4) wide not plain nostar collabels(none) ///
			nogap nomti noobs nonote nonum label keep() append
		}
		
		local v 13 46 79 1012 
		foreach k of local v {
			est drop _all
			
			gen temp = abs(cv_`k') > abs(b_`k') 
			egen temp2 = sum(temp)
			gen pval_`k' = temp2/999
			drop temp*
			mean pval_`k' 
			est sto pval
			
			esttab _all using "Output\cv`a'_`s'fe.csv", ///
			b(4) wide not plain nostar collabels(none) ///
			nogap nomti noobs nonote nonum label keep() append
		}
		
		graph combine c_13 c_46 c_79 c_1012, name(hist`s'_`a'fe, replace) ///
		title() saving(Output\hist_`s'_`a'fe, replace) ///
		graphregion(fcolor(white) lcolor(white)) scheme(s2mono) 
		graph export "Output\hist_`s'_`a'fe.pdf", replace
	}
}

log close