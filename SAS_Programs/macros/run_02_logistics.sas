/*
#############################################################################
Objective:
	Synthesize Logistics-related inputs into grades
	(Replaces the `02 Logistics Industry 20xx.xlsx` workbook)

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

%macro run_02_logistics;

	/* ############################ */
	/* ### Make Empty Scorecard ### */
	/* ############################ */

	proc sql;
		create table lgstc_data as
		select fips, state
		from shared.state_fips
		;
	quit;

	%assert_row_count_equals(lgstc_data, 50);
	
	/* ############################ */
	/* ### Logistics Employment ### */
	/* ############################ */

	%get_data(bea, sa25n);
	%ensure_numeric(sa25n, emplmnt);
	%get_latest_data(sa25n, emp_latest);

	proc sql;
		create table lgstc_emp as
		select distinct fips, state, year, sum(emplmnt) as lgstc_emp
		from emp_latest
		where LineCode=600 or LineCode=800 /* 600 = Wholesale, 800 = Transportation an Warehousing */
		group by fips
		;
	quit;

	proc sql;
		create table tot_emp
		as select FIPS, State, Year, Emplmnt as emp
		from emp_latest
		where LineCode=10 /* LineCode 10 = Total Employment */
		;
	quit;

	proc sql;
		create table lgstc_data as
		select d.*, l.year as emp_year, l.lgstc_emp/t.emp as lgstc_emp_share
		from lgstc_data d
		inner join lgstc_emp l
			on d.fips = l.fips
		inner join tot_emp t
			on t.fips = l.fips and t.year = l.year
		;
	quit;

	%assert_row_count_equals(lgstc_data, 50);


	/* ################################# */
	/* ### Logistics Personal Income ### */
	/* ################################# */

	%get_data(bea, sa5n);
	%ensure_numeric(sa5n, pers_inc);
	%get_latest_data(sa5n, latest_sa5n);

	proc sql;
		create table tot_pi
		as select FIPS, State, Year, Pers_Inc as Tot_PI
		from latest_sa5n
		where LineCode=10 /* LineCode 10 = Total Personal Income */
		;
	quit;

	proc sql;
		create table lgstc_pi
		as select distinct FIPS, State, Year, sum(Pers_Inc) as Lgstc_PI
		from latest_sa5n
		where LineCode=600 or LineCode=800 /* 600 = Wholesale, 800 = Transportation an Warehousing */
		group by fips
		;
	quit;

	proc sql;
		create table lgstc_data as
		select d.*, l.year as pi_year, lgstc_pi/tot_pi as lgstc_pi_share
		from lgstc_data d
		inner join lgstc_pi l
			on d.fips = l.fips
		inner join tot_pi t
			on t.fips = l.fips
		;
	quit;

	%assert_row_count_equals(lgstc_data, 50);


	/* ############################ */
	/* ###### Commodity Flows ##### */
	/* ############################ */

	%get_data(census, commodity_flows);
	%ensure_numeric(commodity_flows, value);
	%ensure_numeric(commodity_flows, tons);
	%ensure_numeric(commodity_flows, tonmiles);
	%get_latest_data(commodity_flows, recent_flows);

	%get_data(census, popset); /* contains overall population data */
	%ensure_numeric(popset, popest);

	/* Rail	*/
	proc sql;
		create table rail_flows as
		select f.fips, f.state, f.year, f.value/p.popest as rail_flows_per_capita
		from recent_flows f
		inner join	popset p
		on f.year = p.year and f.fips = p.fips
		where mode = 'Rail'
		;
	quit;

	/* Road */
	proc sql;
		create table road_flows as
		select f.fips, f.state, f.year, f.value/p.popest as road_flows_per_capita
		from recent_flows f
		inner join	popset p
		on f.year = p.year and f.fips = p.fips
		where mode = 'Truck'
		;
	quit;

	/* Shipped Value, tons, ton-miles */
	proc sql;
		create table shipping_all_modes as
		select fips, state, year, value as ship_val, tons as ship_tons, tonmiles as ship_tonmiles
		from recent_flows
		where mode = 'All modes'
		;
	quit;

	/* Add flows to final Data */
	proc sql;
		create table lgstc_data as
		select d.*, rail.year as flows_year, rail.rail_flows_per_capita, road.road_flows_per_capita, a.ship_val, a.ship_tons, a.ship_tonmiles
		from lgstc_data d
		inner join rail_flows rail
			on d.fips = rail.fips
		inner join road_flows road
			on d.fips = road.fips
		inner join shipping_all_modes a
			on d.fips = a.fips
		;
	quit;

	/* Calculate subcategory ranks */
	proc rank descending ties=low
		data = lgstc_data
		out=lgstc_data;
		var 
			ship_val
			ship_tons
			ship_tonmiles
			;
		ranks
			score_ship_val /* Don't use "rank", because this is a sub-category */
			score_ship_tons
			score_ship_tonmiles
			;
	run;

	/* take the average shipping rank */
	data lgstc_data;
		set lgstc_data;
		score_shipping = mean(score_ship_val, score_ship_tons, score_ship_tonmiles);
	run;


	%assert_row_count_equals(lgstc_data, 50);


	/* ######################################### */
	/* ### State Infrastructure Expenditures ### */
	/* ######################################### */

	/* Note: up to 5 most recent years of data are used in calculations */
	/* (SA5N already imported and cleaned in a previous Logistics calculation) */

	%get_data(census, highway_exp);
	%ensure_numeric(highway_exp, hway_expend);
	%get_latest_data(highway_exp, latest_highway_exp, num_years=5);

	/* same as above, but for all years */
	proc sql;
		create table tot_pi
		as select FIPS, State, Year, Pers_Inc as Tot_PI
		from sa5n
		where LineCode=10 /* LineCode 10 = Total Personal Income */
		;
	quit;

	proc sql;
		create table avg_hwy_exp as
		select distinct h.fips, min(h.year) as hwy_start, max(h.year) as hwy_end, avg(hway_expend/tot_pi) as avg_hwy_exp_perc
		from latest_highway_exp h
		inner join tot_pi p
			on p.fips = h.fips and p.year = h.year
		group by h.fips
		;
	quit;

	proc sql;
		create table lgstc_data as
		select d.*, h.hwy_start, h.hwy_end, h.avg_hwy_exp_perc
		from lgstc_data d
		inner join avg_hwy_exp h
			on d.fips = h.fips
		;
	quit;

	%assert_row_count_equals(lgstc_data, 50);


	/* ###################################### */
	/* ### FHWA Infrastructure Investment ### */
	/* ###################################### */
	
	%get_data(dot_fhwa, infr_inv);
	%ensure_numeric(infr_inv, oblig_tot);
	%get_latest_data(infr_inv, latest_inf_inv);

	/* popset loaded above */

	proc sql;
		create table lgstc_data as
		select d.*, i.year as FHWA_year, i.oblig_tot as total_fhwa_funds
		from lgstc_data d
		inner join latest_inf_inv i
			on d.fips = i.fips
		inner join popset p
			on i.fips = p.fips and i.year = p.year
		;
	quit;

	%assert_row_count_equals(lgstc_data, 50);


	/* ########################### */
	/* ###### Finalize Data ###### */
	/* ########################### */

	/* Calculate Individual Category Ranks */
	proc rank descending ties=low /* high is good */
		data = lgstc_data
		out = lgstc_data;
		var 
			lgstc_emp_share
			lgstc_pi_share
			rail_flows_per_capita
			road_flows_per_capita
			avg_hwy_exp_perc
			total_fhwa_funds
			;
		ranks
			rank_lgstc_emp
			rank_lgstc_pi_share
			rank_rail_flows
			rank_road_flows
			rank_hwy_exp
			rank_tot_fhwa_funds
			;
	run;

	proc rank ties = low /* low is good */
		data = lgstc_data
		out = lgstc_data;
		var score_shipping;
		ranks rank_shipping;
	run;

	%assert_row_count_equals(lgstc_data, 50);

	/* Calculate Grades */
	%create_gradesheet(lgstc_data, lgstc_grades);
	%assert_row_count_equals(lgstc_grades, 50);

	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_02_Logistics;
		set lgstc_data;
		attrib _all_ label=" ";
	run;

	data out.grades_02_Logistics;
		set lgstc_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();
	
%mend run_02_logistics;
