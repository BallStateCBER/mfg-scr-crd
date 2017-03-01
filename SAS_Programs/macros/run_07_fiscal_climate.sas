/*
#############################################################################
Objective:
	Synthesize Tax/Fiscal Climate inputs into grades
	(Replaces the `07 Tax Climate Fiscal Climate 20xx.xlsx` workbook)

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

	Many data import steps will throw errors due to non-numeric values.
	These are recorded as missing values, which is OK.

	Currently assumes hard-coded column labels in the input csv data.
	No human-readable column labels yet, but those might be good to add later.

#############################################################################
*/

%macro run_07_fiscal_climate;

	/* ############################################### */
	/* #### State Business Tax Climate Index Data #### */
	/* ############################################### */

	%get_data(tax_foundation, business_tax_climate);
	%ensure_numeric(business_tax_climate, corp_tax_rank);
	%ensure_numeric(business_tax_climate, inc_tax_rank);
	%ensure_numeric(business_tax_climate, sales_tax_rank);
	%ensure_numeric(business_tax_climate, unemp_ins_tax_rank);
	%ensure_numeric(business_tax_climate, property_tax_rank);
	%get_latest_data(business_tax_climate, latest_tax_climate);

	proc sql;
		create table fisc_clim_data as
		select fips, state, year as tax_year, corp_tax_rank, inc_tax_rank, sales_tax_rank, unemp_ins_tax_rank, property_tax_rank
		from latest_tax_climate
		;
	quit;

	%assert_row_count_equals(fisc_clim_data, 50);


	/* (The inputs are rank data, no further processing is required) */

	/* Calculate Grades */
	%create_gradesheet(fisc_clim_data, fisc_clim_grades);
	%assert_row_count_equals(fisc_clim_grades, 50);

	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_07_Fiscal_Climate;
		set fisc_clim_data;
		attrib _all_ label=" ";
	run;

	data out.grades_07_Fiscal_Climate;
		set fisc_clim_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();


%mend run_07_fiscal_climate;
