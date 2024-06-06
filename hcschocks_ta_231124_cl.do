cd "H:\Documents\HC shocks"
import excel "Data\globalterrorismdb_0522dist.xlsx", firstrow clear

sum
keep iyear imonth iday country_txt nkill nkillter nwound nwoundte
rename i* *
rename *_txt country
codebook country

keep if inrange(year, 2004, 2014)
tab country
unique country

// check that country names match names in 45 and up data
preserve
merge m:1 country using "Data\country_abs_iso"
tab country if _merge ==1 
restore

preserve 
use  "Data\country_abs_iso", clear
tab country
restore

replace country = "Bosnia and Herzegovina" if country == "Bosnia-Herzegovina"
replace country = "China (excludes SARs and Taiwan)" if country == "China"
replace country = "Congo, Democratic Republic of" if country == "Democratic Republic of the Congo"
replace country = "Hong Kong (SAR of China)" if country == "Hong Kong"
replace country = "Côte d'Ivoire" if country == "Ivory Coast" 
replace country = "Former Yugoslav Republic of Macedonia (FYROM)" if country == "Macedonia"
replace country = "Burma (Myanmar)" if country == "Myanmar"
replace country = "Congo" if country == "Republic of the Congo"
replace country = "Russian Federation" if country == "Russia"
replace country = "Serbia" if country == "Serbia-Montenegro"
replace country = "Korea, Republic of (South)" if country == "South Korea"
replace country = "United Kingdom, Channel Islands and Isle of Man" if country == "United Kingdom"
replace country = "United States of America" if country == "United States"
replace country = "Gaza Strip and West Bank" if country == "West Bank and Gaza Strip"

sum
compress
save "Data\terra_raw", replace 

* Create indicators for major disasters by country-year-month
use "Data\terra_raw", clear

sum n*
describe
gen nkillnt = nkill - nkillter
gen nkillwound = nkill + nwound
gen nkillwoundnt = nkill + nwound - nkillter - nwoundte
sum n*
//browse if nkillwoundnt < 0
drop nkillter nwoundte

foreach k of varlist n* {
	sum `k' if `k' > 0, detail 
}

* Agrregate by day
foreach k of varlist n* {
	rename `k' temp
	bysort country year month day: egen `k' = sum(temp)
	drop temp
}

bysort country year month day: gen temp = _n
tab temp
keep if temp == 1
drop temp day

* Normalize by population 
* Add ISO code
merge m:1 country using "Data\country_abs_iso.dta", keepusing(iso)
drop if _merge ==2 
drop _merge 
* Merge
describe using  "Data\pop_hc"
rename country Country
merge m:1 iso year using "Data\pop_hc"
tab Country if _merge ==1 // No pop data for Taiwan, Kosovo, Western Sahara
tab iso if _merge ==1 // ISO codes (ESH, TWN, ZZZ)
tab country if _merge ==2 
tab Country if _merge == 3
drop if _merge == 2
drop _merge country
rename Country country 

local u kill wound killwound killnt killwoundnt
foreach k of local u {
	gen r`k' = (n`k'/pop)*100000
}
sum r* 

local u kill wound killwound killnt killwoundnt
foreach k of local u {
	gen geq1pp`k' = r`k' >= 1 if !missing(r`k')
	gen geq5pp`k' = r`k' >= 5 if !missing(r`k')
}
sum geq*
drop r* pop

/* Fatalities/+injuries per 100,000 low (<5/10) - don't normalise by pop.
Terrorist acts are salient enough, even if # fatalieties/injuries is low.*/
// 1 - 10 - 100
sum nkillwoundnt, detail
local u kill wound killnt killwound killwoundnt
foreach k of local u {
	gen geq1`k' = n`k' >= 1 if !missing(n`k')
	gen geq10`k' = n`k' >= 10 if !missing(n`k')
	gen geq100`k' = n`k' >= 100 if !missing(n`k')
}
sum geq*

list year month country if geq1ppkillwoundnt == 1
list year month country if geq5ppkillwoundnt == 1
list year month country if geq100killwoundnt == 1

gen terra = 1

keep iso country year month terra geq*
sort iso year month
//browse iso year month terra

* Collapse to # of major ter acts by country-year-month
sort iso year month 
foreach k of varlist terra geq* {
	rename `k' temp
	bysort iso year month: egen `k' = sum(temp)
	drop temp
}
sum terra geq*
//browse if terra > 100

bysort iso year month: gen temp = _n
keep if temp == 1 
drop temp

sum 
compress
save "Data\temp\temp_terra1.dta", replace

* Long file country-year-month // see hcshocks_nd* do-file, based on countries in 45 and up data
describe using "Data\temp\cc_names_dis_long.dta"
use "Data\temp\cc_names_dis_long.dta", clear
merge 1:1 iso year month using "Data\temp\temp_terra1.dta"
tab country if _merge == 2 // no migrants from these countries in 45 and up
drop if _merge == 2
//drop country

// Countries from 45 and up  not in terrorist act database at all = not captured/no ter act 2004-14 (more likely)
preserve
drop _merge
merge m:1 iso using "Data\country_abs_iso.dta", keepusing(country)
tab iso if _merge == 1
drop if _merge == 2
keep if terra ==. 
bysort iso: gen temp2 = _N
tab country if temp2 == 132, miss 

keep if temp2 == 132
bysort iso: gen temp3 = _n
keep if temp3 == 1
list iso country
restore

drop _merge 

foreach k of varlist terra geq*  {
	replace `k' = 0 if missing(`k') 
}

foreach k of varlist geq*pp*  {
	replace `k' = . if ///
	inlist(iso, "ESH", "TWN", "ZZZ") // no pop data
}

sum terra geq*, detail

* How many major attacks? 
preserve 
keep if inrange(year,2005,2013) | (year == 2004 & inrange(month,3,12)) | ///
(year == 2014 & inrange(month, 1,9))
keep if mmgr200 == 1
list year month country if geq1ppkillwoundnt >= 1 & geq1ppkillwoundnt != . 
list year month country if geq5ppkillwoundnt >= 1 & geq5ppkillwoundnt != . 
//list year month country if geq10killwoundnt >= 1 & geq100killwoundnt != . 
list year month country if geq100killwoundnt >= 1 & geq100killwoundnt != . 
restore

* # acts n months ago, n = 1,...,24
sort iso year month  
egen t = group(year month)
encode iso, gen(isonum)
xtset isonum t 

foreach k of varlist terra geq* {
	forvalues i = 1/24 {
		bysort isonum (t):  gen `k'`i'm = L`i'.`k'
		label var `k'`i'm "#`k' `i' months ago"
	}
}

drop t 

sum
save "Data\temp\temp_terra2.dta", replace

* Create counts of/indicators for ter acts in last X-X months
use "Data\temp\temp_terra2.dta", clear

local u terra 
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

local u kill wound killwound killnt killwoundnt
foreach l of local u {
	foreach k of numlist 1 5 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			* Indicator
			gen geq`k'pp`l'l`lb'`ub'm_i = 0 
			forvalues j = `lb'/`ub' {
				replace geq`k'pp`l'l`lb'`ub'm_i = 1  if geq`k'pp`l'`j'm >= 1
			}
			forvalues j = `lb'/`ub' {
				replace geq`k'pp`l'l`lb'`ub'm_i = .  if geq`k'pp`l'`j'm == .
			}
			label var geq`k'pp`l'l`lb'`ub'm_i "`l' last `lb'-`ub' months"
		}
	}
}

local u kill wound killwound killnt killwoundnt
foreach l of local u {
	foreach k of numlist 1 10 100 {
		forvalues i = 0/5 {
			local lb = 1 + `i'*3  
			local ub = 3 + `i'*3
			* Indicator
			gen geq`k'`l'l`lb'`ub'm_i = 0 
			forvalues j = `lb'/`ub' {
				replace geq`k'`l'l`lb'`ub'm_i = 1  if geq`k'`l'`j'm >= 1
			}
			forvalues j = `lb'/`ub' {
				replace geq`k'`l'l`lb'`ub'm_i = .  if geq`k'`l'`j'm == .
			}
			label var geq`k'`l'l`lb'`ub'm_i "`l' last `lb'-`ub' months"
		}
	}
}

drop *m
drop country

mean *_i *_n, //format(%9.4f)
compress
save "Data\temp\temp_terra4.dta", replace

use "Data\temp\temp_terra4.dta", clear
duplicates report iso year month
unique iso year month

