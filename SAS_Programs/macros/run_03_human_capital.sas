/*
#############################################################################
Objective:
	Synthesize Human-Capital-related inputs into grades
	(Replaces the `03 Human Capital 20xx.xlsx` workbook)

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

%macro run_03_human_capital;

	/* ############################ */
	/* ### Make Empty Scorecard ### */
	/* ############################ */

	proc sql;
		create table hmn_cap_data as
		select fips, state
		from shared.state_fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);

	
	/* ############################## */
	/* ### Educational Attainment ### */
	/* ############################## */

	%get_data(census, acs5_15001);
	%ensure_numeric(acs5_15001, Pop_18_plus);
	%ensure_numeric(acs5_15001, HS_plus);
	%ensure_numeric(acs5_15001, Bach_exact);
	%get_latest_data(acs5_15001, edu_att_latest);

	proc sql;
		create table hmn_cap_data as
		select d.*, e.year as edu_att_yr, hs_plus/pop_18_plus as perc_HS_plus, bach_exact/pop_18_plus as perc_Bach_deg
		from hmn_cap_data d
		inner join edu_att_latest e
		on d.fips=e.fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);

	
	/* ############################ */
	/* ###### Retention Rate ###### */
	/* ############################ */

	%get_data(nces, retention_rates);
	%ensure_numeric(retention_rates, reten_rt);
	%get_latest_data(retention_rates, retention_latest);

	proc sql;
		create table hmn_cap_data as
		select d.*, r.year as ret_yr, reten_rt as retention_rate
		from hmn_cap_data d
		inner join retention_latest r
		on d.fips=r.fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);


	/* ############################ */
	/* #### AA Graduation Rate #### */
	/* ############################ */

	%get_data(nces, aa_grad_rates);
	%ensure_numeric(aa_grad_rates, aa_grad_150);
	%get_latest_data(aa_grad_rates, aa_grad_latest);

	proc sql;
		create table hmn_cap_data as
		select d.*, a.year as aa_grad_yr, aa_grad_150 as aa_grad_rate
		from hmn_cap_data d
		inner join aa_grad_latest a
		on d.fips=a.fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);


	/* ############################# */
	/* ### Adult Based Education ### */
	/* ############################# */

	%get_data(nces, adult_education);
	%ensure_numeric(adult_education, adlt_edu);
	%get_latest_data(adult_education, adult_edu_latest);

	/* (acs5_15001 already imported in an above step) */

	proc sql;
		create table hmn_cap_data as
		select d.*, edu.year as adlt_edu_yr
			,edu.adlt_edu / (a.pop_18_plus - a.hs_plus) as adult_edu_enroll /* adult_education_participants / adults_with_no_diploma */
		from hmn_cap_data d
		inner join adult_edu_latest edu
			on d.fips=edu.fips
		inner join acs5_15001 a
			on edu.year = a.year and edu.fips = a.fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);


	/* ############################# */
	/* ###### Workers with AA ###### */
	/* ############################# */

	%get_data(census, acs5_16010);
	%ensure_numeric(acs5_16010, pop_25_plus);
	%ensure_numeric(acs5_16010, some_col_labor_force);
	%get_latest_data(acs5_16010, latest_aa_labor_force);

	proc sql;
		create table hmn_cap_data as
		select d.*, l.year as aa_yr, some_col_labor_force/pop_25_plus as perc_aa
		from hmn_cap_data d
		inner join latest_aa_labor_force l
		on d.fips=l.fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);


	/* ############################# */
	/* ### 8th Grade Math Scores ### */
	/* ############################# */

	%get_data(nces, math_scores_8);
	%ensure_numeric(math_scores_8, math_scr_8);
	%get_latest_data(math_scores_8, latest_math_scores);

	proc sql;
		create table hmn_cap_data as
		select d.*, m.year as math_scr_yr, math_scr_8 as math_scores
		from hmn_cap_data d
		inner join latest_math_scores m
		on d.fips = m.fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);


	/* ############################ */
	/* #### HS Graduation Rate #### */
	/* ############################ */

	%get_data(nces, grad_rates);
	%ensure_numeric(grad_rates, grad_rate);
	%get_latest_data(grad_rates, latest_grad_rates);

	proc sql;
		create table hmn_cap_data as
		select d.*, g.year as grad_rate_yr, g.grad_rate
		from hmn_cap_data d
		inner join latest_grad_rates g
		on d.fips = g.fips
		;
	quit;

	%assert_row_count_equals(hmn_cap_data, 50);


	/* ########################### */
	/* ###### Finalize Data ###### */
	/* ########################### */

	/* Calculate Individual Category Ranks */
	proc rank descending ties=low
		data = hmn_cap_data
		out=hmn_cap_data;
		var 
			perc_hs_plus perc_bach_deg retention_rate
			aa_grad_rate adult_edu_enroll perc_aa
			math_scores grad_rate
			;
		ranks
			rank_hs_plus rank_bach_deg rank_retention
			rank_aa_grad rank_adult_edu rank_perc_aa
			rank_math_scores rank_grad_rate
			;
	run;

	%assert_row_count_equals(hmn_cap_data, 50);

	/* Calculate Grades */
	%create_gradesheet(hmn_cap_data, hmn_cap_grades);
	%assert_row_count_equals(hmn_cap_grades, 50);


	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_03_Human_Capital;
		set hmn_cap_data;
		attrib _all_ label=" ";
	run;

	data out.grades_03_Human_Capital;
		set hmn_cap_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();

%mend run_03_human_capital;
