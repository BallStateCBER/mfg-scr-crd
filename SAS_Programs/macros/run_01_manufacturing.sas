/*
#############################################################################
Objective:
	Synthesize Manufacturing-related inputs into grades
	(Replaces the `01 Manufacturing Industry 20xx.xlsx` workbook)

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

%macro run_01_manufacturing;

	/* ##################################### */
	/* ### Manufacturing Personal Income ### */
	/* ##################################### */

	%get_data(folder=BEA, dataset=sa5n);
	%get_latest_data(raw_data=sa5n, destination=latest_sa5n);

	proc sql;
		create table tot_pi
		as select FIPS, State, Year, Pers_Inc as TPI
		from latest_sa5n
		where LineCode=10 /* LineCode 10 = Total Personal Income */
		;
	quit;

	%assert_row_count_equals(tot_pi, 50);

	proc sql;
		create table mfg_pi
		as select FIPS, State, Year, Pers_Inc as TPI
		from latest_sa5n
		where LineCode=500 /* LineCode 500 = Manufacturing Personal Income */
		;
	quit;

	%assert_row_count_equals(mfg_pi, 50);


	/* ################################## */
	/* ### Manufacturing Compensation ### */
	/* ################################## */

	%get_data(folder=BEA, dataset=sa6n);
	%get_latest_data(raw_data=sa6n, destination=latest_sa6n);

	proc sql;
		create table tot_comp
		as select FIPS, State, Year, Tot_Comp as comp
		from latest_sa6n
		where LineCode=1 /* LineCode 1 = Total Compensation */
		;
	quit;

	%assert_row_count_equals(tot_comp, 50);

	proc sql;
		create table mfg_comp
		as select FIPS, State, Year, Tot_Comp as comp
		from latest_sa6n
		where LineCode=500 /* LineCode 500 = Manufacturing Conpensation */
		;
	quit;

	%assert_row_count_equals(mfg_comp, 50);


	/* ################################ */
	/* ### Manufacturing Employment ### */
	/* ################################ */

	%get_data(folder=BEA, dataset=sa25n);
	%get_latest_data(raw_data=sa25n, destination=latest_sa25n);

	proc sql;
		create table tot_emp
		as select FIPS, State, Year, Emplmnt as emp
		from latest_sa25n
		where LineCode=10 /* LineCode 10 = Total Employment */
		;
	quit;

	%assert_row_count_equals(tot_emp, 50);

	proc sql;
		create table mfg_emp
		as select FIPS, State, Year, Emplmnt as emp
		from latest_sa25n
		where LineCode=500 /* LineCode 500 = Manufacturing Employment */
		;
	quit;

	%assert_row_count_equals(mfg_emp, 50);


	/* #################### */
	/* ### Combine Data ### */
	/* #################### */

	proc sql;
		create table mfg_data
		as
		select tot_pi.fips, tot_pi.state, tot_pi.year as pi_yr, tot_pi.TPI as tot_pi,
			mfg_pi.TPI as mfg_pi,
			tot_comp.year as comp_yr, tot_comp.comp as Tot_comp,
			mfg_comp.comp as mfg_comp,
			tot_emp.year as emp_yr, tot_emp.emp as Tot_emp,
			mfg_emp.emp as mfg_emp
		from
			tot_pi inner join mfg_pi on tot_pi.fips = mfg_pi.fips
			inner join tot_comp on tot_pi.fips = tot_comp.fips
			inner join mfg_comp on tot_pi.fips = mfg_comp.fips
			inner join tot_emp on tot_pi.fips = tot_emp.fips
			inner join mfg_emp on tot_pi.fips = mfg_emp.fips
		;
	quit;

	%assert_row_count_equals(mfg_data, 50);

	/* Calculate Metrics */
	data mfg_data;
		set mfg_data;
		mfg_pi_share = mfg_pi/tot_pi;
		mfg_wage_prem = (mfg_comp/mfg_emp)/(tot_comp/tot_emp);
		mfg_emp_share = mfg_emp/tot_emp;
		output;
	run;

	%assert_row_count_equals(mfg_data, 50);

	/* Calculate Individual Category Ranks */
	proc rank descending ties=low
		data = mfg_data
		out=mfg_data;
		var mfg_pi_share mfg_wage_prem mfg_emp_share;
		ranks rank_mfg_pi rank_wage_prem rank_mfg_emp;
	run;

	%assert_row_count_equals(mfg_data, 50);

	/* Calculate Letter Grades (individual and overall) */
	%create_gradesheet(mfg_data, mfg_grades);
	%assert_row_count_equals(mfg_grades, 50);

	/* Output final data to permanant storage */
	data out.values_01_Manufacturing;
		set mfg_data;
		attrib _all_ label=" ";
	run;

	data out.grades_01_Manufacturing;
		set mfg_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();

%mend run_01_manufacturing;
