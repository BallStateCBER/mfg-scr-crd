/*
#############################################################################
Objective:
	Synthesize Manufacturing Diversification inputs into grades
	(Replaces the `08 Diversification 20xx.xlsx` workbook)

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

%macro run_08_diversification;

	%get_data(bea, sa5n);
	%ensure_numeric(sa5n, linecode);
	%ensure_numeric(sa5n, pers_inc);
	%get_latest_data(sa5n, latest_inc);

	/* get total manufacturing personal income */
	data tot_mfg_inc;
		set latest_inc;
		if linecode ^= 500 then delete;
		tot_inc_sq = pers_inc ** 2;
	run;

	/* get individual manufacturing category personal income */
	data mfg_inc_by_category;
		set latest_inc;
		if linecode < 501 or linecode > 599 then delete; /* manufacturing only */
		if linecode = 510 or linecode = 530 then delete; /* throw out durable/non-durable to avoid double-counting */
		cat_inc_sq = pers_inc ** 2;
	run;

	/* create the Herfindahl diversification index from the previous two tables */
	proc sql;
		create table diversification_data as
		select t.fips, t.state, t.year as diversity_year, t.pers_inc as mfg_income,
				sum.sum_inc_sq/t.tot_inc_sq * (100**2) as Herfindahl_index
		from tot_mfg_inc t
		inner join (
			select fips, sum(cat_inc_sq) as sum_inc_sq
			from mfg_inc_by_category
			group by fips
		) sum
		on t.fips = sum.fips
		;
	quit;

	%assert_row_count_equals(diversification_data ,50);

	/* ########################### */
	/* ###### Finalize Data ###### */
	/* ########################### */
	
	/* Calculate Category Ranks */
	proc rank ties=low
		data = diversification_data
		out=diversification_data;
		var 
			Herfindahl_index
			;
		ranks
			rank_diversification
			;
	run;

	%assert_row_count_equals(diversification_data, 50);

	/* Calculate Grades */
	%create_gradesheet(diversification_data, diversification_grades);
	%assert_row_count_equals(diversification_grades, 50);

	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_08_Diversification;
		set diversification_data;
		attrib _all_ label=" ";
	run;

	data out.grades_08_Diversification;
		set diversification_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();

%mend run_08_diversification;
