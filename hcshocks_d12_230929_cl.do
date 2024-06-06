sysdir set PLUS "H:\Documents\ado\plus"
sysdir set PERSONAL "H:\Documents\ado\personal"
cd "H:\Documents\HC shocks"

cap log close 
log using "Output\dataclean.log", replace

* CLEAN SUPPLEMENTARY DATA
do "Data\hcshocks_sd2_230927_cl.do"

* Clean 45 and Up data
* Non-missing CoB data
use "G:\hips_hearts\45andup_1.dta", clear 
foreach k of varlist CofO_* CofO {
	replace `k' = . if CofO == 0 
}
sum CofO_*
sum ppn
keep if !missing(CofO) 
drop if inlist(CofO, 8400, 9100, 912, 913, 8200, 9200) 
sum ppn

gen mgr = !inlist(CofO, 1101, 1102) if !missing(CofO)
tab mgr

rename yeararrivalAust yrarr
gen yrsarr = year- yrarr
unique ppn if yrsarr < 0
replace yrsarr = . if yrsarr < 0 
label var yrarr "Year of arrival"
label var yrsarr "Years since arrival"

gen agearr = age - yrsarr
sum yrarr yrsarr agearr if !missing(yrsarr), detail 

unique CofO

cap drop _merge
rename CofO cofo
merge m:1 cofo using "Data\cc_names.dta" // old code-name file
rename name name1
label var name1 "Country name from cc_names.xlsx" 
tab cofo if _merge ==1
tab name1 if _merge == 2 // no such countries in analysis sample
drop if _merge ==2 
drop _merge 
tab name1 if mgr  == 1 

merge m:1 cofo using "Data\cc_names_2ed.dta" // new code-name file
rename name name2
label var name2 "Country name from CoB_ABS_ISO.xlsx" 
tab cofo if _merge ==1
tab name2 if _merge == 2 // no such countries in analysis sample
drop if _merge ==2 
drop _merge 
tab name2 if mgr  == 1 

drop  mgr

* Indicators for low SES
cap drop seifa_bqnt income_lt20k
gen seifa_bqnt = seifa_1 == 1 | seifa_2 == 1 if ///
!missing(seifa_1, seifa_2)
label var seifa_bqnt "Bottom SEIFA quintile"
tab income if income_miss != 1
gen income_lt20k = inrange(income,1,3) if income_miss != 1
label var income_lt20k "Annual HH income < $20k"

* Marital status
sum marpartn ms_single ms_married ms_partner ms_widowed ms_divorced ms_separated
// Not sure why marpartn has more observations - create own
gen mrdprtn = ms_married == 1 | ms_partner == 1 if !missing(ms_married, ms_partner)
sum mrdprtn
label var mrdprtn "Married/living with partner"

compress
save "Data\45andup_1.dta", replace

* Language at home
use "Data\45andup_1.dta", clear 
keep ppn otherlanghomeyn
tab otherlang
rename otherlanghom flnghm
save "Data\temp\othlang", replace


* Long file ppn-year-month
use "Data\45andup_1.dta", clear 
keep ppn 
sum ppn
forvalues  i = 2004/2014 {
	gen year`i' = . 
} 
reshape long year, i(ppn)
drop year
rename _j year  
 
forvalues i = 1/12 {
gen month`i' = . 
}
reshape long month, i(ppn year)
drop month 
rename _j month 
save "Data\hcshocks0.dta", replace


* Add DRUGS  
use ppn date_of_supply patient_category gross_price net_benefit using "G:\From Sax\New data Mar16\_45andup_pbs_10028_supply", clear

* ADD gross price to calculate expenditure 
use ppn atc_code date_of_supply patient_category pbs_item_code net_benefit gross_price using "G:\From Sax\New data Mar16\_45andup_pbs_10028_supply", clear

drop if missing(atc)
drop if missing(ppn)
drop if missing(date_of_supply)

rename date_of_supply dos
rename patient_category ptntcat 
rename net_benefit netbnft

gen year = year(dos)
gen month = month(dos)
gen quart = quarter(dos)
gen item3=substr(atc,1,3)
gen item4=substr(atc,1,4)
drop atc

destring ptntcat, replace
tab ptntcat
sum netbnft if inlist(ptntcat,1,2,4)
sum netbnft if inlist(ptntcat,3)
sum ppn if netbnft == 0 & year <2012
sum ppn if netbnft == 0 & year >2012
drop netbnft 

// Remove duplicates after recording HCC status
bysort ppn pbs_item_code dos: gen n = _N
tab n 
bysort ppn pbs_item_code dos: gen n2 = _n
bysort ppn pbs_item_code dos: gen temp =  inlist(ptntcat,1,2) if !missing(ptntcat)
bysort ppn pbs_item_code dos: egen cons =  max(temp)
//browse ppn pbs_item_code dos n n2 temp cons if n > 1
keep if n2 == 1
drop n n2 temp ptntcat pbs_item_code dos
summarize

tab year
tab month if year == 2005
tab month if year == 2014
drop if year == 2004
drop if year == 2005 & month < 9
drop if year == 2014 & month >= 11
tab year

* Individuals who used HCCC drugs - by year
preserve
gen cons_a = cons
foreach k of varlist cons_a {
	rename `k' temp
	egen `k' = max(temp), by(ppn year)
	drop temp
}
bysort ppn year: gen index=_n
keep if index==1
keep ppn year cons_a
label var cons_a "Used HCCC this year"
save "Data\hccc.dta" , replace
restore

* Individuals who used HCCC drugs - anytime
preserve
gen cons_a2 = cons
foreach k of varlist cons_a2 {
	rename `k' temp
	egen `k' = max(temp), by(ppn)
	drop temp
}
bysort ppn: gen index=_n
keep if index==1
keep ppn cons_a2
label var cons_a2 "Used HCCC anytime 2005-2014"
save "Data\hccc2.dta", replace
restore 

* Drugs for MH, other conditions
gen pd_mh = inlist(item3, "N05") | inlist(item4,"N06A","N06B","N06C") // all MH drugs - dimentia
gen pd_dpnx = inlist(item4,"N05B", "N05C", "N06A", "N06C") // updated, include sedatives
gen pd_anx = inlist(item4,"N05B", "N05C") 
gen pd_dep = inlist(item4,"N06A") 
gen pd_psch = inlist(item4,"N05A") 
gen pd_dem = inlist(item4, "N06D") //- dementia may be affected by stress
gen pd_mgr = inlist(item4, "N02C") //- migraine may be affected by stress
gen pd_diab = inlist(item3, "A10") //- affected by stress
gen pd_hrt = inlist(item3, "C01", "C02", "C03", "C04", "C05", "C06")
replace pd_hrt = 1 if inlist(item3, "C07", "C08", "C09", "C10")
gen pd_asth = inlist(item3, "R03")
gen pd_ost = inlist(item4, "M05B") // - placebo

tab cons 
tab cons if pd_dpnx == 1
tab cons if pd_mh == 1

* Expenditures on all drugs
sort ppn year month item4
rename gross_price exp_pbs
//browse 

foreach i of varlist pd_* exp_pbs {
	rename `i' temp
	egen `i' = sum(temp), by(ppn year month)
	drop temp
}
bysort ppn year month: gen index=_n
keep if index==1
keep ppn year month pd* exp_pbs

merge 1:1 ppn year month using "Data\hcshocks0.dta"
drop if _merge == 1 
drop _merge 
foreach m of varlist pd* exp_pbs { 
	replace `m' = 0 if missing(`m')
	replace `m' = . if year == 2004 | ///
	(year == 2005 & month < 9) | (year == 2014 & month >= 11)
}

sum pd* exp_pbs
compress
save "Data\pd_0514_mo.dta", replace 


* Add DOCTOR visits 
describe using "G:\From Sax\New data Mar16\_45andup_mbs_update_10028_supply"


use benefit_paid patient_out_of_pocket provider_charge schedule_fee using "G:\From Sax\New data Mar16\_45andup_mbs_update_10028_supply", clear 
sum
sum if  provider_charge < 0
browse if provider_charge < 0

* ADD provider_charge to calculate expenditures 
use ppn date_of_service provider_specialty provider_charge using "G:\From Sax\New data Mar16\_45andup_mbs_update_10028_supply", clear 

sum

rename date dos
rename provider_specialty prspec

gen year = year(dos)
gen month = month(dos)
gen day = day(dos)
drop dos

/*tab prspec year, nol // 38m obs
tab prspec13 year // 2005-08 different codes, no labels, 2m obs - ignore

tab prspec, nol
tab prspec13

sum ppn if missing(prspec) & missing(prspec13)
sum ppn if missing(prspec) & !missing(prspec13)
sum ppn if !missing(prspec13)
drop prspec13*/

* Expenditures by month
rename provider_charge exp_mbs
foreach i of varlist exp_mbs {
	rename `i' temp
	egen `i' = sum(temp), by(ppn year month)
	drop temp
}
preserve
bysort ppn year month: gen index=_n
keep if index==1
keep ppn year month exp_mbs
save "Data\temp\tempexp_mbs", replace
restore
drop exp_mbs

drop if missing(prspec)

gen dv_gp = inlist(prspec, 55, 58, 64, 65, 66, 70, 71, 88, 96, 97, 98)
replace dv_gp = 1 if inlist(prspec, 104, 130) // no "TRAINEE-RACGP"
gen dv_pschtr = inlist(prspec, 18, 40, 100)
// "CP-PSYCHIATRY", "COL-TR-PSYCHI", "PSYCHIATRY"
gen dv_pschl = inlist(prspec, 11, 73)
// "CLINICAL PSYCHOLOGIST", "NON CLINICAL PSYCHOLOGIST"
gen dv_mhp = dv_pschtr == 1 | dv_pschl == 1 
keep if dv_gp == 1 | dv_mhp == 1 

foreach k of varlist dv_gp dv_pschtr dv_pschl dv_mhp {
	preserve
	rename `k' temp1
	egen temp2 = max(temp1), by(ppn year month day)
	bysort ppn year month day: gen index=_n
	keep if index==1
	egen `k' = sum(temp2), by(ppn year month)
	bysort ppn year month: gen index2=_n
	keep if index2==1
	keep ppn year month `k'
	save "Data\temp\temp`k'", replace
	restore 
}

use "Data\hcshocks0.dta", clear
local u dv_gp dv_mhp dv_pschtr dv_pschl exp_mbs
foreach k of local u { 
	merge 1:1 ppn year month using "Data\temp\temp`k'"
	drop if _merge == 2
	drop _merge 
}

foreach m of varlist dv_* exp_mbs { 
	replace `m' = 0 if missing(`m') 
	replace `m' = . if year == 2004 | (year == 2005 & month < 9)
}
compress
sum dv* exp_mbs
sum if exp_mbs < 0 
save "Data\dv_0514_mo.dta", replace


* DEATHS in hospital (2006-09 only)
use  "G:\hips_hearts\apdclinked0009_1.dta", clear
keep if yearsep >= 2006 
gen mosep = month(sepdate)
//browse mosep yearsep sepdate nsepmode
keep ppn yearsep mosep nsepmode
gen diedh = inlist(nsepmode, 6,7)  
tab diedh

sort ppn yearsep mosep
foreach k of varlist diedh {
	rename `k' temp
	egen `k'=max(temp), by(ppn yearsep mosep)
	drop temp
}

bysort ppn yearsep mosep: gen index=_n
keep if index==1
drop index
rename yearsep year 
rename mosep month
bysort year: tab diedh
bysort month: sum diedh

keep ppn year month diedh
save  "Data\deathshosp", replace 
use "Data\deathshosp", clear

* No use of MBS services = dead
use ppn date_of_service using "G:\From Sax\New data Mar16\_45andup_mbs_update_10028_supply", clear 
gen year = year(date_of_service)
drop date_of_service
gen dv = 1

foreach k of varlist dv {
	preserve
	rename `k' temp1
	egen `k' = max(temp1), by(ppn year)
	bysort ppn year: gen index2=_n
	keep if index2==1
	keep ppn year `k'
	save "Data\temp\temp`k'", replace
	restore 
}

use "Data\hcshocks0.dta", clear
local u dv
foreach k of local u { 
	merge m:1 ppn year using "Data\temp\temp`k'"
	drop if _merge == 2
	drop _merge 
}

foreach m of varlist dv*  { 
	replace `m' = 0 if missing(`m') 
	replace `m' = . if year == 2004
}

merge 1:1 ppn year month using "Data\deathshosp"
drop if _merge == 2
drop _merge 
tab diedh
bysort ppn (year month): replace diedh = 1 if diedh[_n-1] == 1 
replace diedh = 0 if missing(diedh)
tab diedh

bysort year: tab dv diedh
//sort ppn year month
//browse ppn year month dv diedh if dv == 1 & diedh == 1 

bysort ppn year (month): egen diedhy = max(diedh)
by ppn year (month): gen temp = _n
keep if temp == 1 
keep ppn year diedhy dv 

bysort year: tab dv diedhy

keep if year >= 2006
gen died = dv == 0 
forvalues i = 1/8 {
	bysort ppn (year): replace died = 0 if dv[_n+`i'] == 1
}
rename died diedmbs
//browse ppn year dv diedmbs diedh

bysort ppn (year): replace diedmbs = 1 if diedmbs[_n+1] == 1 & dv[_n+1] == 0

compress
save "Data\deathsmbs.dta", replace

* MERGE 
use "Data\hcshocks0.dta", clear
merge 1:1 ppn year month using "Data\pd_0514_mo.dta"
drop if _merge == 2 
drop _merge
merge 1:1 ppn year month using "Data\dv_0514_mo.dta"
drop if _merge == 2 
drop _merge
merge m:1 ppn year using "Data\hccc.dta"
drop if _merge == 2 
drop _merge
merge m:1 ppn using "Data\hccc2.dta"
drop if _merge == 2 
drop _merge
merge m:1 ppn year month using "Data\deathshosp.dta"
drop if _merge == 2 
drop _merge
merge m:1 ppn year using "Data\deathsmbs.dta"
drop if _merge == 2 
drop _merge

foreach k of varlist pd_* dv_* {
	gen `k'_i = `k'> 0 if !missing(`k')
	rename `k' `k'_n
}

label var pd_mh_i "Any MH drugs>0"
label var pd_dpnx_i "Depression/Anxiety drugs>0"
label var pd_anx_i "Anxiety drugs>0"
label var pd_dep_i "Depression drugs>0"
label var pd_dem_i "Dementia drugs>0"
label var pd_mgr_i "Migraine drugs>0"
label var pd_diab_i "Diabetes drugs>0"
label var pd_hrt_i "Heart drugs>0"
label var pd_asth_i "Asthma drugs>0"
label var pd_ost_i "Osteoporosis drugs>0"

label var dv_gp_i "GP visits>0"
label var dv_pschtr_i "Psychiatrist visits>0"
label var dv_pschl_i "Psychologist visits>0"
label var dv_mhp_i "MH professional visits>0"

label var pd_mh_n "Any MH drugs #"
label var pd_dpnx_n "Depression/Anxiety drugs #"
label var pd_anx_n "Anxiety drugs #"
label var pd_dep_n "Depression drugs #"
label var pd_dem_n "Dementia drugs #"
label var pd_mgr_n "Migraine drugs #"
label var pd_diab_n "Diabetes drugs #"
label var pd_hrt_n "Heart drugs #"
label var pd_asth_n "Asthma drugs #"
label var pd_ost_n "Osteoporosis drugs #"

label var dv_gp_n "GP visits #"
label var dv_pschtr_n "Psychiatrist visits #"
label var dv_pschl_n "Psychologist visits #"
label var dv_mhp_n "MH professional visits #"

tabstat pd* dv*, by(year)

foreach k of varlist cons_a cons_a2 {
	replace `k' = 0 if missing(`k')
}

tab diedh
bysort ppn (year month): replace diedh = 1 if diedh[_n-1] == 1 
replace diedh = 0 if missing(diedh)
tab diedh
rename diedh diedhym
rename diedmbs diedmbsy 
label var diedhym "Dead (hospital, year-month)"
label var diedmbsy "Dead (MBS, year)"
label var diedhy "Dead (hospital, year)"
rename dv dvy 
label var dvy "Any doctor visits > 0 (year)"

sort ppn year month 
egen t = group(year month), label
order t, after(ppn)
xtset ppn t 
//xtdescribe
bysort ppn: gen temp = _N
tab temp
drop temp 

sum
compress
save "Data\hcshocks1_ym.dta", replace 


* Add SURVEY data 
use "Data\hcshocks1_ym.dta", replace 
merge m:1 ppn using "Data\45andup_1.dta", keepusing(AddrPostCode ///
insurhealthcarecard insurDVA year45up cofo name2 ///
age male Educ_univ seifa_bqnt income_lt20k) 
keep if _merge == 3 
drop _merge
unique ppn 
rename AddrPostCode pcode
label var year45up "Survey year"
label var pcode "Postcode"

gen cons_s = insurhealthcarecard ==1 | insurDVA == 1 if ///
year == year45up & !missing(insurhealthcarecard, insurDVA) 

label var cons_s "HC concession card (s)"
drop insurhealthcarecard insurDVA 

* Code England, etc as UK 
replace cofo = 2100 if inrange(cofo,2101, 2108)

gen age_a = age 
forvalues i = -1/8 {
	local j = `i' + 2006
	replace age_a = age+ `i' if year45up == 2006 & year == `j'
}
forvalues i = -2/7 {
	local j = `i' + 2007
	replace age_a = age+ `i' if year45up == 2007 & year == `j'
}
forvalues i = -3/6 {
	local j = `i' + 2008
	replace age_a = age+ `i' if year45up == 2008 & year == `j'
}
forvalues i = -4/5 {
	local j = `i' + 2009
	replace age_a = age+ `i' if year45up == 2009 & year == `j'
}
forvalues i = -5/4 {
	local j = `i' + 2010
	replace age_a = age+ `i' if year45up == 2010 & year == `j'
}

xtsum age_a
drop age
rename age_a age
//drop year45up

rename _all, lower

label var age "Age"
label var male "Male"
label var educ_univ "University degree"

// Add ISO codes
merge m:1 cofo using "Data\country_abs_iso.dta", keepusing(iso)
tab cofo if _merge == 1 // None, as dropped Yugoslavia and USSR above
drop if _merge == 2
drop _merge

* ADD INDICATORS FOR MAJOR MIGRANT GROUPS IN ANALYSIS SAMPLE (CONCESSIONAL INDIVIDUALS)
preserve
keep ppn cofo iso name2 cons_* year month pd_dpnx_i
* KEEP HCCC holders
sum ppn
keep if cons_s == 1 | cons_a == 1 | year == 2004
sum ppn
* Drop obs in 2004 for those never observed with HCC in 2005-14
bysort ppn: egen temp = max(year)
tab temp 
drop if temp == 2004
drop temp 
sum ppn
* Keep migrants
drop if inlist(cofo, 1101, 1102) // Australia/ Norfolk Island
drop if cofo == . // no observations dropped
* Non-missing drug data
keep if !missing(pd_dpnx_i)

keep ppn cofo iso name2
bysort ppn: gen temp = _n
keep if temp == 1

bysort cofo: gen Number = _N
bysort cofo: gen temp2 = _n
keep if temp2 == 1

drop temp* ppn 

gen mmgr200 = Number >= 200
gen mmgr100 = Number >= 100

tab name2 if mmgr200 == 1

order cofo name2 iso
gsort - Number 

merge 1:1 iso using "Data\temp\ndis_mmgr200"
drop _merge 

compress
save "Data\temp\major_mgr_gr2", replace

drop iso cofo 
export excel using "Output\major_mgr_gr2.xlsx", firstrow(variables) replace
restore

drop name2

cap drop mmgr*
merge m:1 cofo using "Data\temp\major_mgr_gr2", keepusing(mmgr200 mmgr100)
drop if _merge == 2 
drop _merge
sum mmgr*

compress 
save "Data\hcshocks2_ym.dta", replace


* ADD NATURAL DISASTER INDICATORS
* Clean ND data 
do "Data\hcschocks_nd6_230929_cl"

use "Data\hcshocks2_ym.dta", clear
merge m:1 iso year month using "Data\temp\temp_dis4.dta", keepusing(disdir10l13m_i disdir10l46m_i disdir10l79m_i disdir10l1012m_i disl13m_i disl13m_n dispp1l13m_i dispp5l13m_i dispp10l13m_i disdir1l13m_i disdir5l13m_i)
drop if _merge == 2
drop _merge

compress
save "Data\hcshocks3_ym.dta", replace 


* ANALYSIS SAMPLE + SUMMARY STATISTICS BY HCC AND MIGRANT STATUS
use "Data\hcshocks3_ym.dta", clear
sort ppn year month

* Drop observations with no pop data 
browse ppn year month iso pd_mh_i disl13m_i disdir10l13m_i if disl13m_i!= . & disdir10l13m_i == . 
tab iso  if disl13m_i!= . & disdir10l13m_i == . 
unique ppn if disl13m_i!= . & disdir10l13m_i == .  // Only 19 (16 concessional) individuals from Cook Islands

keep if !missing(disdir10l13m_i) // also drops observations for all in Jan-Mar 2004

* Extrapolate HCC status
sum ppn
describe cons*
sum ppn cons*
mean cons*
tab cons_s cons_a2
tab cons_a cons_a2

tabstat cons*, by(year)

foreach k of varlist cons_a cons_s {
	bysort ppn (year month): replace `k' = 1 if `k'[_n-1] == 1 
}

merge m:1 ppn using "Data\45andup_1.dta", keepusing(year45up) 
keep if _merge == 3 
drop _merge
replace cons_s = 0 if missing(cons_s) & year >= year45up

tabstat cons*, by(year)

* HCC vs no HCC
preserve
* Drop observations with no drug data
keep if !missing(pd_dpnx_i)

* Drop obs with no info on HCC
drop if cons_s == . & cons_a == . 
gen cons_sa = cons_s == 1 | cons_a == 1 
sum cons_sa

gen mgr = !inlist(cofo, 1101, 1102) if !missing(cofo)
label var mgr "Migrant"

* Descriptive statistics by HCC status
est drop _all
forvalues i = 0/1 {
	estpost sum mgr male age educ_uni income_lt20k seifa_bqnt ///
	pd_dpnx_i pd_dep_i pd_anx_i dv_mhp_i dv_pschtr_i dv_pschl_i ///
	if cons_sa == `i'
	eststo hcc`i'
	unique ppn if cons_sa == `i'
}
esttab _all using "Output\ss_byhcc.csv", ///
cell("mean count")  ///
nogap mti obs nonote nonum label keep() plain replace 
esttab _all using "Output\ss_byhcc.tex", ///
cell("mean") b(3) ///
fragment booktabs ///
nogap nomti noobs nonote nonum label keep() replace
		
* Effects on MH specialist & GP visits by HCC status 
local u disdir // 
foreach l of local u {
	foreach k of numlist 10 {
		forvalues i = 0/3 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			label var `l'`k'l`lb'`ub'm_i "`lb'-`ub'"
		}
	}
}

xtset ppn t 
foreach s of varlist  mmgr200  { //mgrmmgr200
	local u dir // pp
	foreach l of local u {
		foreach k of numlist 10 {
			est drop _all
			local v dv_mhp_i dv_gp_i
			foreach y of local v {
				foreach m of numlist 1 0 {
					xtreg `y' ///
					dis`l'`k'l13m_i dis`l'`k'l46m_i ///
					dis`l'`k'l79m_i dis`l'`k'l1012m_i ///
					i.t if `s' == 1 & cons_sa == `m', cluster(cofo) fe
					sum `y' if e(sample) == 1 
					estadd scalar mean = r(mean)
					est sto `y'hcc`m'
					coefplot `y'hcc`m', keep(disdir`k'l13m_i disdir`k'l46m_i disdir`k'l79m_i disdir`k'l1012m_i) vertical 			graphregion(color(white)) yline(0) xtitle("Months after disaster") name(gr`s'`y'c`m', replace) omitted scheme(sj)
				graph save "Output\gr`s'`y'c`m'", replace				
				}
			}
		esttab _all using "Output\mhspcgp_`s'fe.csv", ///
		b(4) se star(* 0.10 ** 0.05 *** 0.01) ///
		scalars("mean Mean (dep var)" "N Sample size") sfmt(4 0) ///
		nogap mti obs nonote nonum label keep(*dis*) replace 
		esttab dv_mhp_i* using "Output\mhspcgp_`s'fe.tex", ///
		b(4) se wide star(* 0.10 ** 0.05 *** 0.01) ///
		fragment booktabs ///
		scalars("mean Mean (dep var)") sfmt(4) ///
		nogap nomti noobs nonote nonum label keep(*dis*) replace
		}
	}
}
restore

graph combine grmmgr200dv_mhp_ic1 grmmgr200dv_mhp_ic0 
// Changed scheme to Stata journal (2nd)
graph save "Output\grmmgr200dv.gph", replace
graph export "Output\grmmgr200dv.pdf", replace
graph export "Output\grmmgr200dv.tif", replace
graph export "Output\grmmgr200dv.eps", replace


* KEEP HCCC holders
sum ppn
keep if cons_s == 1 | cons_a == 1 | year == 2004
sum ppn
* Drop obs in 2004 for those never observed with HCC in 2005-14
bysort ppn: egen temp = max(year)
tab temp 
drop if temp == 2004
drop temp 
sum ppn

* Generate indicator for migrant
gen mgr = !inlist(cofo, 1101, 1102) if !missing(cofo)
label var mgr "Migrant"

* Summary statistics by migrant status
preserve
// Keep observations with non-missing drug info
keep if !missing(pd_dpnx_i)
gen nmgr = mgr == 0  if !missing(mgr)
sum nmgr mgr mmgr100 mmgr200  
est drop _all
local u nmgr mgr mmgr100 mmgr200 
foreach l of local u {
	estpost sum male age educ_uni income_lt20k seifa_bqnt ///
	pd_* dv_* if `l' == 1
	eststo ss_`l'
	unique ppn if  `l' == 1
}
esttab _all using "Output\ss_bymgr.csv", ///
cell("mean count")  ///
nogap mti obs nonote nonum label keep() plain replace
esttab _all using "Output\ss_bymgr.tex", ///
cell("mean") b(3) ///
fragment booktabs ///
nogap nomti noobs nonote nonum label keep(mgr male age educ_uni income_lt20k seifa_bqnt
	pd_dpnx_i pd_dep_i pd_anx_i dv_mhp_i dv_pschtr_i dv_pschl_i) replace
restore

* KEEP MIGRANTS 
drop if missing(cofo)
drop if inlist(cofo, 1101, 1102) // Australia/ Norfolk Island
sum ppn

unique ppn
sum
compress
save "Data\hcshocks4pd_ym.dta", replace 

* ADD ALL NATURAL DISASTER DATA
use "Data\hcshocks4pd_ym.dta", clear
sum ppn mgr mmgr200 cofo t if !missing(dv_mhp_i)

drop dis*_*
merge m:1 iso year month using "Data\temp\temp_dis4.dta" 
tab namend if _merge == 2 // no individuals from such countries in 45&Up
drop if _merge == 2
drop _merge

tab dis, miss
sort ppn year month

foreach k of varlist dis disclmgeo dishydro dismeteo {
	gen `k'_i = `k'> 0 if !missing(`k')
	rename `k' `k'_n
}
foreach k of varlist dis*1 dis*5 dis*10 {
	gen `k'_i = `k'> 0 if !missing(`k')
	drop `k'
}
placevar dis_i disclmgeo_i dishydro_i dismeteo_i dis*1_i dis*5_i dis*10_i, after(dis_n)

label var disclmgeo_n "# Earthquake/Volcanic/Wildfire"
label var dishydro_n "# Flood/Landslide"
label var dismeteo_n "# Storm/Extreme temp"
label var dis_n "# Natural disaster"

label var disclmgeo_i "Earthquake/Volcanic/Wildfire"
label var dishydro_i "Flood/Landslide"
label var dismeteo_i "Storm/Extreme temp"
label var dis_i "Natural disaster"
foreach i of numlist 1 5 10  {
	label var dispp`i'_i "Affected pop >=`i'%"
	label var disdir`i'_i "Dead/injured >= `i' per 100,000"
}

cap drop temp*
cap drop _merge
compress
save "Data\hcshocks5pd_ym.dta", replace 

* Add HC ECONOMIC VARIABLES
use "Data\hcshocks5pd_ym.dta", clear

* SACC2 name
merge m:1 cofo using "Data\cc_names_2ed.dta"
tab cofo if _merge ==1
tab name if _merge == 2 // no such countries in analysis sample
drop if _merge ==2 
drop _merge 
tab name if inrange(cofo, 2100, 2109)
tab cofo if inrange(cofo, 2100, 2109)

* GDP, GDP GROWTH, UNEMPLOYMENT
local u gdp gdpg unemp 
foreach k of local u {
	merge m:1 iso year using "Data\hc`k'.dta"
	tab name if _merge == 1 
	tab iso if _merge == 2 
	tab year if _merge == 2
	drop if _merge == 2 
	drop _merge
}
duplicates report cofo
duplicates report cofo if !missing(hcgdp,hcur)
tab name if missing(hcgdp) | missing(hcur)

* Distance
merge m:1 name using "Data\hcdist.dta"
tab name if _merge == 1
tab name if _merge == 2
drop if _merge == 2 
drop _merge 

compress
save "Data\hcshocks6pd_ym", replace

* ADD LOCAL AREA SPECIFIC VARIABLES 
* HOME COUNTRY MIGRANT POP 2006-2011-2016 - POSTCODE LEVEL 
use "Data\hcshocks6pd_ym", clear
destring pcode, replace force
tab pcode
local u 06 11 16 
foreach k of local u { 
	merge m:1 name pcode using "Data\hcpop_pcode_`k'.dta"
	di "20`k'"
	duplicates report pcode if _merge ==1 
	tab pcode if _merge ==1
	duplicates report pcode if _merge ==2
	tab pcode if _merge ==2
	drop if _merge == 2
	drop _merge
}

gen hcpop = hcpop06
replace hcpop = hcpop11 if inrange(year, 2009, 2013)
replace hcpop = hcpop16 if inrange(year, 2014, 2018)
label var hcpop "HC in postcode (extrapolated)"

gen temp1 =  hcpop11 - hcpop06
gen temp2 =  hcpop16 - hcpop11
gen hcpopg = temp1
replace hcpopg = temp2 if year > 2011
label var hcpopg "HC population growth" 
drop temp*

compress 
save "Data\hcshocks8pd_ym.dta", replace

* HISTORY OF DISEASES
use "Data\hcshocks3_ym", clear
keep if !inlist(cofo, 1101, 1102, .) 
keep pd_dpnx_i pd_diab_i pd_hrt_i pd_asth_i ppn t
sum pd_dpnx_i pd_diab_i pd_hrt_i pd_asth_i ppn t

sort ppn t
local u pd_dpnx pd_diab pd_hrt pd_asth
foreach l of local u {
	forvalues i = 24/24 {
		cap drop `l'l19`i'm_i 
		gen `l'l19`i'm_i = 0 
		forvalues j = 19/`i' {
			bysort ppn (t): replace `l'l19`i'm_i = 1  if `l'_i[_n-`j'] == 1
		}
		forvalues j = 19/`i' {
			bysort ppn (t): replace `l'l19`i'm_i = .  if `l'_i[_n-`j'] == .
		}
			label var `l'l19`i'm_i "Last 19-`i' months"
	}
	forvalues i = 18/18 {
		cap drop `l'l13`i'm_i 
		gen `l'l13`i'm_i = 0 
		forvalues j = 13/`i' {
			bysort ppn (t): replace `l'l13`i'm_i = 1  if `l'_i[_n-`j'] == 1
		}
		forvalues j = 13/`i' {
			bysort ppn (t): replace `l'l13`i'm_i = .  if `l'_i[_n-`j'] == .
		}
			label var `l'l13`i'm_i "Last 13-`i' months"
	}
}
sum pd_*l1318m_i pd_*l1924m_i, sep(4)
save "Data\hcshocks_pdh_ym", replace

use "Data\hcshocks8pd_ym.dta", replace 
merge 1:1 ppn t using "Data\hcshocks_pdh_ym", 
drop if _merge == 2
drop _merge

cap drop temp*
cap drop _merge*
cap drop _est*
compress
save "Data\hcshocks10pd_ym", replace

* CREATE ADDITIONAL VARIABLES
use "Data\hcshocks10pd_ym.dta", replace 

merge m:1 ppn using "Data\45andup_1.dta", keepusing(yrarr) 
keep if _merge == 3 
drop _merge
unique ppn 

gen cofo_r = . 
foreach i of numlist 11/16 21/24 31/33 41/42 51/52 61/62 71/72  ///
81/84 91/92 {
replace cofo_r = `i' if inrange(cofo, `i'00, `i'99)
}
replace cofo_r = 32 if inlist(cofo, 913)
replace cofo_r = 33 if inlist(cofo, 912)

sum cofo cofo_r
label def cofo_r 11 "Australia" 12 "New Zealand" 13 "Melanesia" ///
14 "Micronesia" 15 "Polynesia" 16 "Antarctica" 21 "UK" ///
22 "Ireland" 23 "Western Europe" 24 "Northern Europe" ///
31 "Southern Europe" 32 "South Eastern Europe" 33 "Eastern Europe" ///
41 "North Africa" 42 "Middle East" 51 "Mainland SE Asia" ///
52 "Maritime SE Asia" 61 "Chinese Asia" 62 "Japan and the Koreas" ///
71 "Southern Asia" 72 "Central Asia" 81 "Northern America" ///
82 "South America" 83 "Central America" 84 "Caribbean" ///
91 "Central and West Africa" 92 "Southern and East Africa" 
label val cofo_r cofo_r
tab cofo_r

gen cofo_r2 = cofo_r
replace cofo_r2 = 12 if inrange(cofo_r, 12,16)
replace cofo_r2 = 21 if inrange(cofo_r, 21,24)
replace cofo_r2 = 32 if inrange(cofo_r, 32,33)
replace cofo_r2 = 41 if inrange(cofo_r, 41,42)
replace cofo_r2 = 51 if inrange(cofo_r, 51,62)
replace cofo_r2 = 71 if inrange(cofo_r, 71,72)
replace cofo_r2 = 82 if inrange(cofo_r, 82,84)
replace cofo_r2 = 91 if inlist(cofo_r, 91,92)
label def cofo_r2 11 "Australia" 12 "NZ & Pacific islands" ///
21 "Western/Northern Europe" 31 "Southern Europe" ///
32 "South Eastern/Eastern Europe" ///
41 "Middle East & North Africa" 51 "Eastern Asia" ///
71 "Central/Southern Asia" /// 
81 "Northern America" 82 "South/Central America" 91 "Africa", modify
label val cofo_r2 cofo_r2
tab cofo_r2
tab cofo_r cofo_r2
label var cofo_r "Region of birth"
label var cofo_r2 "Region of birth 2"

gen cofo_r3 = cofo_r2
replace cofo_r3 = 22 if inrange(cofo_r2, 21,32)
replace cofo_r3 = 42 if inlist(cofo_r2, 41,91)
replace cofo_r3 = 52 if inrange(cofo_r2, 51,71)
replace cofo_r3 = 82 if inrange(cofo_r2, 81,82)
label def cofo_r3 11 "Australia" 12 "NZ & Pacific islands" ///
22 "Europe" 42 "Middle East & Africa" 52 "Asia" 82 "Americas", modify
label val cofo_r3 cofo_r3
tab cofo_r3, miss
tab cofo_r2 cofo_r3, miss
label var cofo_r3 "Region of birth"

rename _all, lower
rename name name45up

* KEEP observations with NON-MISSING DRUG DATA
keep if !missing(pd_dpnx_i)

* Label variables
local u dis 
foreach l of local u {
	forvalues i = 0/5 {
		local lb = 1 + `i'*3  
		local ub = 3 + `i'*3
		* Indicator
		label var `l'l`lb'`ub'm_i "`lb'-`ub' months"
		* Count
		label var `l'l`lb'`ub'm_n "`lb'-`ub' months"
	}
}

local u dispp disdir disclmgeopp disclmgeodir ///
dishydropp dishydrodir dismeteopp dismeteodir 
foreach l of local u {
	foreach k of numlist 1 5 10 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			* Indicator
			label var `l'`k'l`lb'`ub'm_i "`lb'-`ub' months"
		}
	}
}

compress
save "Data\hcshocks11pd_ym.dta", replace 

* Drop type of disaster variables
use "Data\hcshocks11pd_ym.dta", clear 

drop disclmgeo* dishydro* dismeteo* 
placevar dis_i, after(dis_n)

placevar cofo_r cofo_r2  cofo_r3 yrarr mgr* mmgr*, after(cofo)
placevar year45up, before(pcode) 

sum ppn cofo t 
duplicates report ppn
preserve 
keep if mmgr200 == 1
sum ppn cofo t 
unique ppn
restore

compress
save "Data\hcshocks12pd_ym.dta", replace 

cap log close 

