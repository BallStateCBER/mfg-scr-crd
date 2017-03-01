/*
#############################################################################
Objective:
	Synthesize Productivity and Innovation inputs into grades
	(Replaces the `06 Productivity and Innovation 20xx.xlsx` workbook)

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

%macro run_06_prod_and_innov;

	/* ############################ */
	/* ### Make Empty Scorecard ### */
	/* ############################ */

	proc sql;
		create table productivity_data as
		select fips, state
		from shared.state_fips
		;
	quit;

	%assert_row_count_equals(productivity_data, 50);

	
	/* ########################################### */
	/* ### Growth in Manufacturing Value Added ### */
	/* ########################################### */

	%get_data(census, asm_gas_statistics);
	%ensure_numeric(asm_gas_statistics, value_added);
	%get_latest_data(asm_gas_statistics, historic_value_added, num_years=3);

	proc sql;
		create table productivity_data as
		select distinct d.*, f.year as growth_from_year, t.year as growth_to_year, (t.value_added/f.value_added - 1)*100 as value_growth
		from productivity_data d
		inner join (
			select *
			from historic_value_added
			having year = max(year)
			) t
		on d.fips = t.fips
		inner join (
			select *
			from historic_value_added
			having year = min(year)
			) f
		on d.fips = f.fips
		;
	quit;

	%assert_row_count_equals(productivity_data, 50);


	/* ################################ */
	/* ### Research and Development ### */
	/* ################################ */

	%get_data(NSF, res_dev_spending);
	%ensure_numeric(res_dev_spending, total);
	%get_latest_data(res_dev_spending, latest_resdev);

	%get_data(census, popset);
	%ensure_numeric(popset, popest);

	proc sql;
		create table productivity_data as
		select distinct d.*, r.year as resdev_year, r.total/p.popest as resdev_per_capita
		from productivity_data d
		inner join latest_resdev r
			on r.fips = d.fips
		inner join popset p
			on p.fips = r.fips and p.year = r.year
		;
	quit;

	%assert_row_count_equals(productivity_data, 50);


	/* ########################## */
	/* ### Patents Per Capita ### */
	/* ########################## */

	%get_data(uspto, patents);
	%ensure_numeric(patents, patents);
	%get_latest_data(patents, latest_patents);

	%get_data(census, popset);
	%ensure_numeric(popset, popest);

	proc sql;
		create table productivity_data as
		select distinct d.*, p.year as patent_year, p.patents/popset.popest*1000000 as patents_per_capita
		from productivity_data d
		inner join latest_patents p
		on p.fips = d.fips
		inner join popset
		on p.year = popset.year and p.fips = popset.fips
		;
	quit;

	%assert_row_count_equals(productivity_data, 50);


	/* ################################## */
	/* ### Manufacturing Productivity ### */
	/* ################################## */

	%get_data(bea, gdp_curr);
	%ensure_numeric(gdp_curr, gdp_curr);
	%ensure_numeric(gdp_curr, linecode);
	%get_latest_data(gdp_curr, latest_gdp);

	%get_data(bea, sa25n);
	%ensure_numeric(sa25n, emplmnt);
	%ensure_numeric(sa25n, linecode);

	proc sql;
		create table productivity_data as
		select distinct d.*, gdp.year as prod_year, gdp.gdp_curr/emp.emplmnt as mfg_productivity
		from productivity_data d
		inner join (
			select *
			from latest_gdp
			where desc="Manufacturing"
		)gdp
		on gdp.fips = d.fips
		inner join (
			select *
			from sa25n
			where desc="Manufacturing"
		) emp
		on emp.year = gdp.year and emp.fips = gdp.fips
		;
	quit;

	%assert_row_count_equals(productivity_data, 50);


	/* ########################### */
	/* ###### Finalize Data ###### */
	/* ########################### */
	
	/* Calculate Individual Category Ranks */
	proc rank descending ties=low
		data = productivity_data
		out=productivity_data;
		var 
			value_growth
			resdev_per_capita
			patents_per_capita
			mfg_productivity
			;
		ranks
			rank_value_growth
			rank_resdev
			rank_patents
			rank_mfg_productivity
			;
	run;

	%assert_row_count_equals(productivity_data, 50);

	/* Calculate Grades */
	%create_gradesheet(productivity_data, productivity_grades);
	%assert_row_count_equals(productivity_grades, 50);


	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_06_Prod_and_Innov;
		set productivity_data;
		attrib _all_ label=" ";
	run;

	data out.grades_06_Prod_and_Innov;
		set productivity_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();
	
%mend run_06_prod_and_innov;
