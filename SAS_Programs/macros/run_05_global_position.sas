/*
#############################################################################
Objective:
	Synthesize Global-Position-related inputs into grades
	(Replaces the `03 Global Position 20xx.xlsx` workbook)

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

	Many data import steps will throw errors due to non-numeric values.
	These are recorded as missing values, which is OK.

	Currently assumes hard-coded column labels in the input csv data.
	No human-readable column labels yet, but those might be good to add later.

	(Several subcategories have VERY old data, and will be replaced this year.
	They have been recorded with placeholder zeros for now.)

#############################################################################
*/

%macro run_05_global_position;

	/* ############################ */
	/* ### Make Empty Scorecard ### */
	/* ############################ */

	proc sql;
		create table glob_pos_data as
		select fips, state
		from shared.state_fips
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);
	
	/* ################################################ */
	/* ### Durable Manufacturing Exports per Capita ### */
	/* ################################################ */

	%get_data(TSE, durable_exports);
	%ensure_numeric(durable_exports, dur_exp);
	%get_latest_data(durable_exports, latest_dur_exp);

	%get_data(census, popset);
	%ensure_numeric(popset, popest);

	proc sql;
		create table glob_pos_data as
		select d.*, e.year as dur_exp_year, e.dur_exp/p.popest as dur_exp_per_capita
		from glob_pos_data d
		inner join latest_dur_exp e
			on d.fips = e.fips
		inner join popset p
			on e.fips = p.fips and e.year = p.year
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);
	
	/* #################################################### */
	/* ### Non-Durable Manufacturing Exports per Capita ### */
	/* #################################################### */

	%get_data(TSE, non_durable_exports);
	%ensure_numeric(non_durable_exports, nondur_exp);
	%get_latest_data(non_durable_exports, latest_non_dur_exp);

	/* (Population data loaded above) */

	proc sql;
		create table glob_pos_data as
		select d.*, e.year as non_dur_exp_year, e.nondur_exp/p.popest as non_dur_exp_per_capita
		from glob_pos_data d
		inner join latest_non_dur_exp e
			on d.fips = e.fips
		inner join popset p
			on e.fips = p.fips and e.year = p.year
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);
	

	/* ############################################################## */
	/* ### Manufacturing Income from Foreign-Owned Manufactureres ### */
	/* ############################################################## */

	/*
	Remove from code if/when we decide to get rid of this unchanging metric
	*/
	%get_data(Custom, Income_FOM);
	%ensure_numeric(Income_FOM, per_cap_PI_frgn_owned);
	%get_latest_data(Income_FOM, latest_PIFOM)


	proc sql;
		create table glob_pos_data as
		select d.*, l.year as PI_FOM_year, l.per_cap_PI_frgn_owned as PCI_Foreign_Owned
		from glob_pos_data d
		inner join latest_PIFOM l
		on d.fips = l.fips
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);


	/* ##################### */
	/* ### Export Growth ### */
	/* ##################### */

	%get_data(census, exports);
	%ensure_numeric(exports, mfg_exports);
	%ensure_numeric(exports, reexports);
	%get_latest_data(exports, historic_foreign_trade, num_years = 3);
	
	proc sql;
		create table glob_pos_data as
		select distinct d.*, f.year as growth_from_year, t.year as growth_to_year, (t.mfg_exports/f.mfg_exports - 1)*100 as export_growth
		from glob_pos_data d
		inner join (
			select *
			from historic_foreign_trade
			having year = max(year)
			) t
		on d.fips = t.fips
		inner join (
			select *
			from historic_foreign_trade
			having year = min(year)
			) f
		on d.fips = f.fips
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);


	/* ####################################### */
	/* ###### Demand Adaptability Index ###### */
	/* ####################################### */

	%get_data(custom, demand_adaptability);
	%ensure_numeric(demand_adaptability, dmnd_adpt_indx);
	%get_latest_data(demand_adaptability, latest_adaptability);

	proc sql;
		create table glob_pos_data as
		select d.*, l.year as adapt_year, l.dmnd_adpt_indx as demand_adaptability
		from glob_pos_data d
		inner join latest_adaptability l
		on d.fips = l.fips
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);


	/* ######################################## */
	/* ###### Exports percent of Imports ###### */
	/* ######################################## */

	/* (census exports data loaded above) */
	%get_latest_data(exports, latest_exports);

	%get_data(census, imports);
	%ensure_numeric(imports, mfg_imports);
	%get_latest_data(imports, latest_imports);

	proc sql;
		create table glob_pos_data as
		select d.*, e.year as exp_per_imp_year, e.mfg_exports/i.mfg_imports as exp_per_imp
		from glob_pos_data d
		inner join latest_exports e
		on d.fips = e.fips
		inner join latest_imports i
		on d.fips = i.fips
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);


	/* ################################## */
	/* ###### Reexports per Capita ###### */
	/* ################################## */

	/* (lastest_exports loaded above) */
	/* (popest loaded above) */

	proc sql;
		create table glob_pos_data as
		select d.*, e.year as reexp_year, e.reexports/p.popest as reexp_per_capita
		from glob_pos_data d
		inner join latest_exports e
			on d.fips = e.fips
		inner join popset p
			on e.fips = p.fips and e.year = p.year
		;
	quit;

	%assert_row_count_equals(glob_pos_data, 50);


	/* ########################### */
	/* ###### Finalize Data ###### */
	/* ########################### */

	/* Calculate Individual Category Ranks */
	proc rank descending ties=low
		data = glob_pos_data
		out=glob_pos_data;
		var 
			dur_exp_per_capita
			non_dur_exp_per_capita
			PCI_Foreign_Owned
			export_growth
			demand_adaptability
			exp_per_imp
			reexp_per_capita
			;
		ranks
			rank_dur_exp
			rank_non_dur_exp
			rank_PCI_Foreign
			rank_export_growth
			rank_Demand_Adaptability
			rank_exp_per_imp
			rank_reexp
			;
	run;

	%assert_row_count_equals(glob_pos_data, 50);

	/* Calculate Grades */
	%create_gradesheet(glob_pos_data, glob_pos_grades);
	%assert_row_count_equals(glob_pos_grades, 50);

	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_05_Global_Position;
		set glob_pos_data;
		attrib _all_ label=" ";
	run;

	data out.grades_05_Global_Position;
		set glob_pos_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();

%mend run_05_global_position;
