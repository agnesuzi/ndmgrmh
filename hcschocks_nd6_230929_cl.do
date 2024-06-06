import excel "Data\disasters_raw.xlsx", /// 
sheet("data") cellrange(A1:Z7231) firstrow clear

sum
tab end_year
replace end_year = 2014 if end_year == 2201
gen temp = end_year - start_year 
tab temp
drop temp

drop year end_* *_day 
rename start_year year 
rename start_month month 
rename country_name name 
replace name = "Serbia" if name == "Serbia Montenegro" // OLD
replace iso = "SRB" if iso == "SCG" // new
save "Data\disasters_raw", replace 

* MERGE ON ISO ALPHA CODE
// check that all iso codes in nat disaster data in country_abs_iso
preserve
merge m:1 iso using "Data\country_abs_iso"
tab name if _merge ==1 // canary islands not in country_abs_iso or names_cc but ok
tab country if _merge == 2
restore

// check that all countries in 45 & up data in country_abs_iso
preserve
use "Data\45andup_1.dta", clear 
cap drop _merge
merge m:1 cofo using "Data\country_abs_iso"
tab cofo if _merge ==1 // no channel islands (but coded later as UK), former USSR, Yugoslavia  in country_abs_iso
tab country if _merge == 2
restore

use "Data\disasters_raw", replace 

* Keep natural, non-bio disasters
tab dis_group
keep if dis_group == "Natural"

tab dis_subgroup
drop if dis_subgroup == "Biological"

tab dis_type

sum total_* no_* if dis_type=="Extreme temperature "
//browse if dis_type=="Extreme temperature "
drop if inlist(dis_type, "Drought") // !! EDITED!!

tab dis_subtype dis_type
tab dis_type dis_subgroup
tab dis_subtype dis_subgroup

sum 
drop if month == .

tab dis_subgroup
replace dis_subgroup = "Climatological/Geophysical" if ///
inlist(dis_subgroup, "Climatological", "Geophysical")
tab dis_subgroup

tab dis_subgroup, gen(dt_)
describe dt_*
local new clmgeo hydro meteo
tokenize `new'
forvalues i = 1/3 {
	rename dt_`i' dis``i''
}
label var disclmgeo "Earthquake/Volcanic/Wildfire"
label var dishydro "Flood/Landslide"
label var dismeteo "Storm/Extreme temp"

tab dis_subtype if disclmgeo ==1
gen disgrmov = dis_subtype == "Ground movement" if !missing(dis_subtype)
gen distsnm = dis_subtype == "Tsunami" if !missing(dis_subtype)
label var disgrmov "Ground movement (earthquake)"
label var distsnm "Tsunami (earthquake)"

gen dis = 1 
label var dis "Natural disaster"

* Normalize by population 
* Import population data
preserve
import excel "Data\POP_WB.xls", sheet("Data") cellrange(A4:BH268) clear
rename _all, lower
rename a country
rename b iso
drop c d
local i = 1960
foreach k of varlist e-bh {
	rename `k' pop`i'
	local i = `i' + 1
}

drop in 1/1
destring pop*, replace
reshape long pop, i(iso) j(year)
label var pop "Home country population"
sum
compress
save "Data\pop_hc.dta", replace
restore 


* Merge
merge m:1 iso year using "Data\pop_hc"
tab name if _merge ==1 // No pop data for Taiwan ans small islands but not in major mmgr
tab iso if _merge ==1 // code major dis as missing for these ISO codes below (COK, GLP, MSR, MTQ, NIU, REU, SPI, TKL, TWN, WLF)
tab country if _merge ==2 
tab name if _merge == 3
drop if _merge == 2
drop _merge  

rename total_deaths no_deaths
gen no_dthinj = no_deaths + no_injured
order no_dthinj, after(no_injured)
replace total_affected =  total_affected + no_deaths
rename total_dam000US, lower
destring total_dam000us, replace
sum no_* total_* , detail 

foreach k of varlist no_* total_* {
	sum `k' if `k' > 0, detail 
}

sum pop
gen pctpop_affected = (total_affected / pop)*100
gen r_dthinj = (no_dthinj / pop)*100000
sum pctpop r_dthinj, detail
//browse if missing(pctpop)
//browse if pctpop > 100 & !missing(pctpop) // 1 obs St Lucia
replace pctpop = 100 if pctpop > 100 & !missing(pctpop)

foreach i of numlist 1 5 10  {
	foreach l of varlist dis disclmgeo dishydro dismeteo {

		gen `l'pp`i' = `l' == 1 & pctpop_affected >= `i' if !missing(pctpop_affected)
		label var `l'pp`i' "`l' affected >= `i' of pop"
		
		gen `l'dir`i' = `l' == 1 & r_dthinj >= `i' if !missing(r_dthinj)
		label var `l'dir`i' "Dead/injured in `l' >= `i' per 100,000"
	}
}

foreach i of numlist 10  { // new 
	foreach l of varlist disgrmov distsnm {
		gen `l'dir`i' = `l' == 1 & r_dthinj >= `i' if !missing(r_dthinj)
		label var `l'dir`i' "Dead/injured in `l' >= `i' per 100,000"
	}
}

keep iso name year month dis*
drop dis_*
order iso year month
sort iso year month
//browse name iso year month dis

* Collapse to # of disasters by country-year-month
sort iso year month 
foreach k of varlist dis*  {
	rename `k' temp
	bysort iso year month: egen `k' = sum(temp)
	drop temp
}

bysort iso year month: gen temp = _n
keep if temp == 1 
drop temp

sum 
compress
save "Data\temp\temp_dis1.dta", replace

* Long file country-year-month 
use "Data\hcshocks2_ym.dta", clear
keep iso mmgr200
tab iso
sort iso
egen tag = tag(iso)
keep if tag == 1 
drop tag

forvalues  i = 2004/2014 {
	gen temp`i' = . 
} 
reshape long temp, i(iso) j(year)
drop temp
 
forvalues i = 1/12 {
gen temp`i' = . 
}
reshape long temp, i(iso year) j(month)
drop temp 
save "Data\temp\cc_names_dis_long.dta", replace

* Merge 
use "Data\temp\cc_names_dis_long.dta", clear
merge 1:1 iso year month using "Data\temp\temp_dis1.dta"
tab name if _merge == 2 // no migrants from these countries in 45 and up
drop if _merge == 2

// Countries from 45 and up  not in disaster database at all = not captured/no disaster (more likely)
preserve
drop _merge
merge m:1 iso using "Data\country_abs_iso.dta", keepusing(country)
tab iso if _merge == 1
drop if _merge == 2
keep if dis ==. 
bysort iso: gen temp2 = _N
tab country if temp2 == 132, miss 

keep if temp2 == 132
bysort iso: gen temp3 = _n
keep if temp3 == 1
list iso country
restore

drop _merge 

foreach k of varlist dis disclmgeo dishydro dismeteo disgrmov distsnm {
	replace `k' = 0 if missing(`k') 
	//replace `k' = . if inlist(cofo, 8400, 9100, 912, 913, 8200, 9200) // undefined CoB - OLD
}

foreach k of varlist *pp* *dir*  {
	replace `k' = 0 if missing(`k')
	replace `k' = . if ///
	inlist(iso, ("COK", "GLP", "MSR", "MTQ", "NIU", "REU", "SPI", "TKL", "TWN", "WLF")) // no pop data
}

* Number of disasters in major migrant countries - NEW
preserve
// Keep obs from Sep 2004 to Sep 2014
egen t = group(year month)
keep if inrange(t, 9, 129)
// Keep major migrant groups
keep if mmgr200 == 1
keep iso t year month disdir*
foreach i of numlist 1 5 10  {
	bysort iso: egen ndisdir`i' = sum(disdir`i')
}
bysort iso: gen temp2 = _n
keep if temp2 == 1
keep iso ndisdir*
save "Data\temp\ndis_mmgr200", replace
restore

drop mmgr200

label var disclmgeo "Earthquake/Volcanic/Wildfire"
label var dishydro "Flood/Landslide"
label var dismeteo "Storm/Extreme temperature"
label var dis "Natural disaster"
label var disgrmov "Ground movement (earthquake)"
label var distsnm "Tsunami (earthquake)"

* # disasters n months ago, n = 1,...,36
sort iso year month  
egen t = group(year month)
encode iso, gen(isonum)
xtset isonum t 

foreach k of varlist dis disclmgeo dishydro dismeteo  *pp* *dir* {
	forvalues i = 1/36 {
		bysort isonum (t):  gen `k'`i'm = L`i'.`k'
		label var `k'`i'm "`k' `i' months ago"
	}
}

sum
save "Data\temp\temp_dis2.dta", replace

* Create counts of/indicators for disaster(s) in last X months
use "Data\temp\temp_dis2.dta", clear
drop t

local u dis 
foreach l of local u {
	forvalues i = 3(3)24 {
		* Indicator
		gen `l'l1`i'm_i = 0 
		forvalues j = 1/`i' {
			replace `l'l1`i'm_i = 1  if `l'`j'm >= 1
		}
		forvalues j = 1/`i' {
			replace `l'l1`i'm_i = .  if `l'`j'm == .
		}
		label var `l'l1`i'm_i "`l'  last `i' months"
		
		* Count
		gen `l'l1`i'm_n = 0 
		forvalues j = 1/`i' {
			replace `l'l1`i'm_n = `l'l1`i'm_n + `l'`j'm
		}
		label var `l'l1`i'm_n "# `l'  last `i' months"
	}
}

local u dispp disdir disclmgeopp disclmgeodir ///
dishydropp dishydrodir dismeteopp dismeteodir 
foreach l of local u {
	foreach k of numlist 1 5 10 {
		forvalues i = 3(3)24 {
			gen `l'`k'l1`i'm_i = 0 
			forvalues j = 1/`i' {
				replace `l'`k'l1`i'm_i = 1  if `l'`k'`j'm >= 1
			}
			forvalues j = 1/`i' {
				replace `l'`k'l1`i'm_i = .  if `l'`k'`j'm == .
			}
			label var `l'`k'l1`i'm_i "`l' `k' last `i' months"
		}
	}
}

drop *m

sum
save "Data\temp\temp_dis3.dta", replace
use "Data\temp\temp_dis3.dta", clear

* Create counts of/indicators for disaster(s) in last X-X months
use "Data\temp\temp_dis2.dta", clear
drop t 

local u dis 
foreach l of local u {
	forvalues i = 0/5 {
		local lb = 1 + `i'*3  
		local ub = 3 + `i'*3
		* Indicator
		gen `l'l`lb'`ub'm_i = 0 
		forvalues j = `lb'/`ub' {
			replace `l'l`lb'`ub'm_i = 1  if `l'`j'm >= 1
		}
		forvalues j = `lb'/`ub' {
			replace `l'l`lb'`ub'm_i = .  if `l'`j'm == .
		}
		label var `l'l`lb'`ub'm_i "`l' last `lb'-`ub' months"
		* Count
		gen `l'l`lb'`ub'm_n = 0 
		forvalues j = `lb'/`ub' {
			replace `l'l`lb'`ub'm_n = `l'l`lb'`ub'm_n + `l'`j'm
		}
		label var `l'l`lb'`ub'm_n "# `l' last `lb'-`ub' months"
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
			gen `l'`k'l`lb'`ub'm_i = 0 
			forvalues j = `lb'/`ub' {
				replace `l'`k'l`lb'`ub'm_i = 1  if `l'`k'`j'm >= 1
			}
			forvalues j = `lb'/`ub' {
				replace `l'`k'l`lb'`ub'm_i = .  if `l'`k'`j'm == .
			}
			label var `l'`k'l`lb'`ub'm_i "`l' `k' last `lb'-`ub' months"
		}
	}
}

local u disgrmovdir distsnmdir // new
foreach l of local u {
	foreach k of numlist 10 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			* Indicator
			gen `l'`k'l`lb'`ub'm_i = 0 
			forvalues j = `lb'/`ub' {
				replace `l'`k'l`lb'`ub'm_i = 1  if `l'`k'`j'm >= 1
			}
			forvalues j = `lb'/`ub' {
				replace `l'`k'l`lb'`ub'm_i = .  if `l'`k'`j'm == .
			}
			label var `l'`k'l`lb'`ub'm_i "`l' `k' last `lb'-`ub' months"
		}
	}
}

* Disasters in last 13-24 and 25-36 months - NEW
local u disdir 
foreach l of local u {
	foreach k of numlist 1 5 10 {
		foreach i of numlist 12 24 {
			local lb = 1 + `i'  
			local ub = 12 + `i'
			* Indicator
			gen `l'`k'l`lb'`ub'm_i = 0 
			forvalues j = `lb'/`ub' {
				replace `l'`k'l`lb'`ub'm_i = 1  if `l'`k'`j'm == 1
			}
			label var `l'`k'l`lb'`ub'm_i "`l' `k' last `lb'-`ub' months"
		}
	}
}

drop *m
rename name namend

mean dis*
save "Data\temp\temp_dis4.dta", replace

use "Data\temp\temp_dis4.dta", clear
duplicates report iso year month
unique iso year month

* Add leads 
use "Data\temp\temp_dis2.dta", clear
drop dis*m
foreach k of varlist disdir1 disdir5 disdir10 {
	forvalues i = 1/24 {
		gen `k'`i'm = F`i'.`k'
		label var `k'`i'm "`k' `i' months ahead"
	}
}
//browse iso year month disdir10*

drop t 

local u  disdir 
foreach l of local u {
	foreach k of numlist 1 5 10 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			* Indicator
			gen `l'`k'n`lb'`ub'm_i = 0 
			forvalues j = `lb'/`ub' {
				replace `l'`k'n`lb'`ub'm_i = 1  if `l'`k'`j'm >= 1
			}
			forvalues j = `lb'/`ub' {
				replace `l'`k'n`lb'`ub'm_i = .  if `l'`k'`j'm == .
			}
			label var `l'`k'n`lb'`ub'm_i "`l' `k' next `lb'-`ub' months"
		}
	}
}

drop *m
rename name namend

mean disdir10*
save "Data\temp\temp_disf.dta", replace
use "Data\temp\temp_disf.dta", clear
