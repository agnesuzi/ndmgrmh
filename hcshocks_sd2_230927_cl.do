* Country codes and names - original list
import excel "Data\cc_names.xlsx", sheet(cc_names) clear
rename A cofo
rename B name 
save "Data\cc_names.dta", replace

* Country codes and names - updated list
import excel "Data\CoB_ABS_ISO.xlsx", clear firstrow
keep Country SACC*
describe
rename _all, lower
rename country name
destring sacc2, replace force
replace sacc2 = sacc1 if sacc2 == .
rename sacc2 cofo
keep name cofo
// Why Italy (3104 in cc_names, ISO = ITA, 380 from iso.org) and South Sudan (4111 in cc_names and ISO = SSD, 728 from iso.org ) missing? - updated
set obs 354
replace name = "Italy" in 352
replace cofo = 3104 in 352
replace name = "South Sudan" in 353
replace cofo = 4111 in 353
replace name = "Channel Islands" in 354
replace cofo = 2101 in 354
label var name "Country of birth (SSAC2 name)" 
label var cofo "Country of birth (SSAC2 code)"
save "Data\cc_names_2ed.dta", replace

// check that cc_names_2ed has all the names in cc_names
preserve
use "Data\cc_names_2ed.dta", clear
sort cofo
rename name name2
merge 1:1 cofo using "Data\cc_names.dta" 
sort cofo
tab name if _merge == 2
/* Not existing any more (USSR, Yugoslavia) or small islands */
tab name2 if _merge == 1
tab name if _merge == 3
restore

* CofO ABS code SACC1/2 to ISO mapping
import excel "Data\CoB_ABS_ISO.xlsx", firstrow clear
rename _all, lower
destring sacc2, replace force
replace sacc2 = sacc1 if sacc2 == .
rename sacc2 cofo
rename isoalpha3 iso
keep country cofo iso
// Add Italy and South Sudand - new 
set obs 353
replace country = "Italy" in 352
replace cofo = 3104 in 352
replace iso = "ITA" in 352
replace country = "South Sudan" in 353
replace cofo = 4111 in 353
replace iso = "SSD" in 353
// Replace ISO for UK from QNA to GBR - new
replace iso = "GBR" if cofo == 2100
drop if missing(cofo)
save "Data\country_abs_iso.dta", replace

* HC MACRO VARIABLES
* Real GDP (in constant US$)
import excel "Data\GDP_WB.xls", sheet("Data") cellrange(B4:BH268) clear
rename _all, lower
rename b iso
drop c d
local i = 1960
foreach k of varlist e-bh {
	rename `k' hcgdp`i'
	local i = `i' + 1
}

drop in 1/1
destring hcgdp*, replace
reshape long hcgdp, i(iso) j(year)
label var hcgdp "Home country GDP pc 2010 US$"
sum
compress
save "Data\hcgdp.dta", replace


* GDP in current USD (nominal GDP per capita in US$)
import excel "Data\gdp_currentUSD_wb.xlsx", sheet("Data") cellrange(B2:BO267) clear
rename _all, lower
rename b iso
drop c d
local i = 1960
foreach k of varlist e-bo {
	rename `k' hcgdpnom`i'
	local i = `i' + 1
}
destring hcgdpnom*, replace force
reshape long hcgdpnom, i(iso) j(year)
label var hcgdpnom "Home country GDP pc US$"
sum
compress
save "Data\hcgdpnom.dta", replace

* CPI
import excel "Data\cpi_wb.xls", sheet("Data") cellrange(B5:BO270) clear
rename _all, lower
rename b iso
drop c d
local i = 1960
foreach k of varlist e-bo {
	rename `k' hccpi`i'
	local i = `i' + 1
}

destring hccpi*, replace force
//drop in 264/266
reshape long hccpi, i(iso) j(year)
label var hccpi "Home country CPI"
sum
compress
save "Data\hccpi.dta", replace


* DISTANCE
import excel "Data\distance.xlsx", clear firstrow
gen name = country1
forvalues i = 2/7 {
	replace name = name + " " + country`i' if !missing(country`i')
}
drop country*
* Match country names to ABS SACC2  
replace name = "Bolivia, Plurinational State of" if name == "Bolivia"
replace name = "Brunei Darussalam" if name == "Brunei"
replace name = "Burma (Republic of the Union of Myanmar)" if name == "Myanmar"
replace name = "China (excludes SARs and Taiwan)" if name == "China"
replace name = "Congo, Republic of" if name == "Republic of the Congo"
replace name = "Former Yugoslav Republic of Macedonia (FYROM)" if name == "Macedonia"
//replace name = "Gaza Strip and West Bank" if name == ""
replace name = "Hong Kong (SAR of China)" if name == "Hong Kong"
replace name = "Korea, Republic of (South)" if name == "South Korea"
replace name = "Macau (SAR of China)" if name == "Macao"
replace name = "Russian Federation" if name == "Russia"
replace name = "St Helena" if name == "Saint Helena"
replace name = "St Vincent and the Grenadines" if name == "Saint Vincent and the Grenadines"
replace name = "Timor-Leste" if name == "East Timor"
replace name = "United Kingdom, Channel Islands and Isle of Man" if ///
name == "United Kingdom"
replace name = "United States of America" if name == "United States"
replace name = "Venezuela, Bolivarian Republic of" if name == "Venezuela"

local u km m 
foreach k of local u {
	label var dist`k' "Distance to HC `k'"
}
sum
compress
save "Data\hcdist.dta", replace

* HOME COUNTRY MIGRANT POP 2006-2011-2016 - POSTCODE LEVEL 
// From ABS Census Table builder - 2001 not available
/* Measured with error, as some ppl didn't report their CoB or 
only reported region*/ 
// Save as excel files first 

* 2006
* Name
import excel "Data\cob2006_pcode_updated.xlsx", cellrange(C4:KA4) clear
foreach k of varlist _all  {
rename `k' name`k'
}
gen id = 1
reshape long name, i(id) string
drop id
/*
merge 1:m name using "temp\tempmf", keepusing(name)
tab name if _merge == 2 // in master file, not in anciliary file
tab name if _merge == 1 // in anciliary file, not in master file
*/
replace	name 	=	"Bolivia, Plurinational State of"	if 	name 	==	"Bolivia"
replace	name 	=	"Burma (Republic of the Union of Myanmar)"	if 	name 	==	"Burma (Myanmar)"
replace	name 	=	"China (excludes SARs and Taiwan)"	if 	name 	==	"China (excludes SARs and Taiwan Province)"
replace	name 	=	"Congo, Republic of"	if 	name 	==	"Congo"
replace	name 	=	"Kyrgyzstan"	if 	name 	==	"Kyrgyz Republic"
replace	name 	=	"Timor-Leste"	if 	name 	==	"East Timor"
replace	name 	=	"United Kingdom, Channel Islands and Isle of Man"	if 	name 	==	"United Kingdom, nfd"
replace	name 	=	"Venezuela, Bolivarian Republic of"	if 	name 	==	"Venezuela"
replace	name 	=	"Vietnam"	if 	name 	==	"Viet Nam"

save "Data\temp\temp06", replace 
use "Data\temp\temp06",  clear 
duplicates report name 

* Data
import excel "Data\cob2006_pcode_updated.xlsx", cellrange(B6:KA620) clear
//browse 

foreach k of varlist C-KA  {
	rename `k' mgr`k'
}

replace B = "9999" if B == "Total"
gen pcode = substr(B,1,4)
destring pcode, replace
drop B
tab pcode
duplicates report pcode 
reshape long mgr, i(pcode) string

merge m:1 _j using "Data\temp\temp06"
drop _merge _j
rename mgr hcpop06
order pcode name hcpop
tab name
sort pcode name

gen temp = ///
name == "Guernsey" | name == "Jersey" | name == "England" | ///
name == "Isle of Man" | name == "Northern Ireland" | name == "Scotland" | ///
name == "Wales" | name == "Channel Islands" | ///
name == "United Kingdom, Channel Islands and Isle of Man"
tab name if temp ==1

bysort pcode: egen temp2 = sum(hcpop) if temp == 1
replace hcpop = temp2 if name == "United Kingdom, Channel Islands and Isle of Man"
drop if name == "Guernsey" | name == "Jersey" | name == "England" | ///
name == "Isle of Man" | name == "Northern Ireland" | name == "Scotland" | ///
name == "Wales" | name == "Channel Islands" 
drop temp*

gen temp1 = hcpop if name == "Total"
bysort pcode: egen temp2 = max(temp1) 
replace hcpop = hcpop / temp2
drop temp*
drop if name == "Total"

gen temp1 = hcpop if pcode == 9999
sort name pcode
bysort name: egen hcpoptot06 = max(temp1) 
drop temp* 
drop if pcode == 9999

label var hcpop06 "HC population density in postcode 2006"
label var hcpoptot06 "HC population density in NSW 2006"
sort pcode name
describe 
save "Data\hcpop_pcode_06", replace
use "Data\hcpop_pcode_06", clear

* 2011	
* Name
import excel "Data\cob2011_pcode_updated.xlsx", cellrange(C4:KI4) clear
foreach k of varlist _all  {
rename `k' name`k'
}
gen id = 1
reshape long name, i(id) string
drop id
/*
merge 1:m name using "temp\tempmf", keepusing(name)
tab name if _merge == 2 // in master file, not in anciliary file
tab name if _merge == 1 // in anciliary file, not in master file
*/
replace	name 	=	"United Kingdom, Channel Islands and Isle of Man" ///
if 	name 	==	"United Kingdom, Channel Islands and Isle of Man, nfd"

save "Data\temp\temp11", replace 

* Data
import excel "Data\cob2011_pcode_updated.xlsx", cellrange(B6:KI618) clear
//browse 
foreach k of varlist C-KI  {
	rename `k' mgr`k'
}

replace B = "9999" if B == "Total"
gen pcode = substr(B,1,4)
destring pcode, replace
drop B
tab pcode
duplicates report pcode 
reshape long mgr, i(pcode) string

merge m:1 _j using "Data\temp\temp11"
drop _merge _j
rename mgr hcpop11
order pcode name hcpop
tab name

gen temp = ///
name == "Guernsey" | name == "Jersey" | name == "England" | ///
name == "Isle of Man" | name == "Northern Ireland" | name == "Scotland" | ///
name == "Wales" | name == "Channel Islands" | ///
name == "United Kingdom, Channel Islands and Isle of Man"
tab name if temp ==1

bysort pcode (name): egen temp2 = sum(hcpop) if temp == 1
replace hcpop = temp2 if name == "United Kingdom, Channel Islands and Isle of Man"
drop if name == "Guernsey" | name == "Jersey" | name == "England" | ///
name == "Isle of Man" | name == "Northern Ireland" | name == "Scotland" | ///
name == "Wales" | name == "Channel Islands" 
drop temp*

gen temp1 = hcpop if name == "Total"
bysort pcode: egen temp2 = max(temp) 
replace hcpop = hcpop / temp2
drop temp*
drop if name == "Total"

gen temp1 = hcpop if pcode == 9999
sort name pcode
bysort name: egen hcpoptot11 = max(temp1) 
drop temp* 
drop if pcode == 9999

label var hcpop11 "HC population density in postcode 2006"
label var hcpoptot11 "HC population density in NSW 2006"
sort pcode name

describe
save "Data\hcpop_pcode_11", replace

* 2016	
* Name
import excel "Data\cob2016_pcode_updated.xlsx", cellrange(B10:KH10) clear
foreach k of varlist _all  {
	rename `k' name`k'
}
gen id = 1
reshape long name, i(id) string
drop id
/*
merge 1:m name using "temp\tempmf", keepusing(name)
tab name if _merge == 2 // in master file, not in anciliary file
tab name if _merge == 1 // in anciliary file, not in master file
*/
replace	name 	=	"Bolivia, Plurinational State of"	if 	name 	==	"Bolivia"
replace	name 	=	"Burma (Republic of the Union of Myanmar)"	if 	name 	==	"Myanmar"
replace	name 	=	"Former Yugoslav Republic of Macedonia (FYROM)"	if 	name 	==	"The former Yugoslav Republic of Macedonia"
replace	name 	=	"United Kingdom, Channel Islands and Isle of Man"	if 	name 	==	"United Kingdom, Channel Islands and Isle of Man, nfd"
replace	name 	=	"Venezuela, Bolivarian Republic of"	if 	name 	==	"Venezuela"

save "Data\temp\temp16", replace 

* Data
import excel "Data\cob2016_pcode_updated.xlsx", cellrange(A12:KH645) clear
//browse
foreach k of varlist B-KH  {
	rename `k' mgr`k'
}

replace A = "9999" if A == "Total"
gen pcode = substr(A,1,4)
destring pcode, replace
drop A
tab pcode
duplicates report pcode 
reshape long mgr, i(pcode) string

merge m:1 _j using "Data\temp\temp16"
drop _merge _j
rename mgr hcpop16
order pcode name hcpop
tab name

gen temp = ///
name == "Guernsey" | name == "Jersey" | name == "England" | ///
name == "Isle of Man" | name == "Northern Ireland" | name == "Scotland" | ///
name == "Wales" | name == "Channel Islands" | ///
name == "United Kingdom, Channel Islands and Isle of Man"
tab name if temp ==1

bysort pcode (name): egen temp2 = sum(hcpop) if temp == 1
replace hcpop = temp2 if name == "United Kingdom, Channel Islands and Isle of Man"
drop if name == "Guernsey" | name == "Jersey" | name == "England" | ///
name == "Isle of Man" | name == "Northern Ireland" | name == "Scotland" | ///
name == "Wales" | name == "Channel Islands" 
drop temp*

gen temp1 = hcpop if name == "Total"
bysort pcode: egen temp2 = max(temp) 
replace hcpop = hcpop / temp2
drop temp*
drop if name == "Total"

gen temp1 = hcpop if pcode == 9999
sort name pcode
bysort name: egen hcpoptot16 = max(temp1) 
drop temp* 
drop if pcode == 9999

label var hcpop16 "HC population density in postcode 2006"
label var hcpoptot16 "HC population density in NSW 2006"
sort pcode name

describe
save "Data\hcpop_pcode_16", replace
