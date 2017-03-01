/*
#############################################################################
Objective:
	Synthesize Benefits-Costs-related inputs into grades
	(Replaces the `03 Benefits Costs 20xx.xlsx` workbook)

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

	Many data import steps will throw errors due to non-numeric values.
	These are recorded as missing values, which is OK.

	Currently assumes hard-coded column labels in the input csv data.
	No human-readable column labels yet, but those might be good to add later.

	Due some oddball rank calculations, ranks in this workbook are calculated in each section instead of at the end

#############################################################################
*/

%macro run_04_benefits_costs;

	/* ############################# */
	/* ### Make Empty Scorecard #### */
	/* ############################# */

	proc sql;
		create table benefits_data as
		select fips, state
		from shared.state_fips
		;
	quit;

	%assert_row_count_equals(benefits_data, 50);

	
	/* ############################# */
	/* ### Health Care Premiums #### */
	/* ############################# */

	%get_data(kff, healthcare_premiums);
	%ensure_numeric(healthcare_premiums, single_premium);
	%ensure_numeric(healthcare_premiums, family_premium);
	%get_latest_data(healthcare_premiums, latest_premiums);

	proc sql;
		create table benefits_data as
		select d.*, p.year as prem_year, p.single_premium, p.family_premium
		from benefits_data d
		inner join latest_premiums p
		on d.fips = p.fips
		;
	quit;

	proc rank ties=low /* ascending - low is good */
		data = benefits_data
		out = benefits_data;
		var single_premium family_premium;
		/* Don't use the "rank" keyword, because we DON'T want these ranks to go in the final scorecard! */
		ranks single_prem_score family_prem_score;
	run;

	/* use the average of single and family ranks as the "rank" for premiums */
	data benefits_data;
		set benefits_data;
		rank_premium = mean(single_prem_score, family_prem_score);
	run;

	%assert_row_count_equals(benefits_data, 50);

	
	/* ############################# */
	/* ### Long-Term Health Care ### */
	/* ############################# */

	%get_data(genworth, long_term_healthcare_costs);
	%ensure_numeric(long_term_healthcare_costs, assisted_living_cost);
	%ensure_numeric(long_term_healthcare_costs, nursing_home_cost);
	%get_latest_data(long_term_healthcare_costs, latest_long_term_costs);

	proc sql;
		create table benefits_data as
		select d.*, c.year as long_costs_yr, c.assisted_living_cost, c.nursing_home_cost
		from benefits_data d
		inner join latest_long_term_costs c
		on d.fips = c.fips
		;
	quit;

	proc rank ties=low /* ascending - low is good */
		data = benefits_data
		out = benefits_data;
		var assisted_living_cost nursing_home_cost;
		/* Don't use the "rank" keyword, because we DON'T want these ranks to go in the final scorecard! */
		ranks assisted_living_score nursing_home_score; 
	run;

	/* use the average of nursing home and assisted living ranks as the "rank" for premiums */
	data benefits_data;
		set benefits_data;
		rank_long_term_cost = mean(assisted_living_score, nursing_home_score);
	run;

	%assert_row_count_equals(benefits_data, 50);
	
	/* ############################# */
	/* ### Worker's Compensation ### */
	/* ############################# */

	%get_data(nasi, workers_comp);
	%ensure_numeric(workers_comp, wc_benefits_paid);
	%get_latest_data(workers_comp, latest_workers_comp);

	proc sql;
		create table benefits_data as
		select d.*, w.year as wc_year, w.wc_benefits_paid as wc_benefits
		from benefits_data d
		inner join latest_workers_comp w
		on d.fips=w.fips
		;
	quit;

	proc rank ties=low /* ascending - low is good */
		data = benefits_data
		out = benefits_data;
		var wc_benefits;
		ranks rank_wc_benefits; 
	run;

	%assert_row_count_equals(benefits_data, 50);
	
	/* ############################# */
	/* ###### Fringe Benefits ###### */
	/* ############################# */

	%get_data(census, ASM_GAS_Supplemental);
	%ensure_numeric(asm_gas_supplemental, benefit);
	%get_latest_data(asm_gas_supplemental, latest_fringe);

	%get_data(census, asm_gas_statistics);
	%ensure_numeric(asm_gas_statistics, annual_pay);

	proc sql;
		create table benefits_data as
		select d.*, f.year as fringe_year, f.benefit/s.annual_pay as fringe_ben_share
		from benefits_data d
		inner join latest_fringe f
			on d.fips=f.fips
		inner join asm_gas_statistics s
			on f.fips = s.fips and f.year = s.year
		;
	quit;

	proc rank ties=low /* ascending - low is good */
		data = benefits_data
		out = benefits_data;
		var fringe_ben_share;
		ranks rank_fringe; 
	run;

	%assert_row_count_equals(benefits_data, 50);
	
	/* ############################ */
	/* ### Federal Expenditures ### */
	/* ############################ */

	%get_data(usa_spending, fed_funds_exp);
	%ensure_numeric(fed_funds_exp, funds_awarded);
	%get_latest_data(fed_funds_exp, latest_funds_awarded);

	%get_data(census, popset);
	%ensure_numeric(popset, popest);


	proc sql;
		create table benefits_data as
		select d.*, f.year as funds_year, f.funds_awarded/p.popest as fed_exp_per_capita
		from benefits_data d
		inner join latest_funds_awarded f
			on d.fips = f.fips
		inner join popset p
			on f.year = p.year and f.fips = p.fips		
		;
	quit;

	proc rank descending ties=low /* high is good */
		data = benefits_data
		out = benefits_data;
		var fed_exp_per_capita;
		ranks rank_fed_exp; 
	run;

	%assert_row_count_equals(benefits_data, 50);


	/* ########################### */
	/* ###### Finalize Data ###### */
	/* ########################### */

	/* (Ranks are calculated in each category for this card, because of multiple abnormal categories) */

	/* Calculate Grades */
	%create_gradesheet(benefits_data, benefits_grades);
	%assert_row_count_equals(benefits_grades, 50);


	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_04_Benefits_Costs;
		set benefits_data;
		attrib _all_ label=" ";
	run;

	data out.grades_04_Benefits_Costs;
		set benefits_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();

%mend run_04_benefits_costs;
