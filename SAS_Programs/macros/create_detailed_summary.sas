/*
#############################################################################
Objective:
	Summarize Data from all cards into a detailed master-list of data
	(for use in detailed summaries and year-to-year comparisons)

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`
	Assumes that all gradecards have already been run successfully

#############################################################################
*/


%macro create_detailed_summary;

	/* Create an empty table for details */
	proc sql;
		create table details (state char 20, Category char 30, Subcategory char 100, sort_order int,
		new_year char 9, new_stat numeric, new_rank numeric,
		old_year char 9, old_stat numeric, old_rank numeric
		);
	quit;


	/* ### 01_Manufacturing ### */

	%_append_category(values_01_manufacturing, "Manufacturing", "Manufacturing Personal Income Share", 101, pi_yr, mfg_pi_share, rank_mfg_pi);
	%_append_category(values_01_manufacturing, "Manufacturing", "Manufacturing Wage Premium", 102, comp_yr, mfg_wage_prem, rank_wage_prem);
	%_append_category(values_01_manufacturing, "Manufacturing", "Manufacturing Employment Share", 103, emp_yr, mfg_emp_share, rank_mfg_emp);
	%_append_final_category(values_01_manufacturing, "Manufacturing", 199);


	/* ### 02_Logistics ### */

	%_append_category(values_02_logistics, "Logistics", "Logistics Share of Personal Income", 201, pi_year, lgstc_pi_share, rank_lgstc_pi_share);
	%_append_category(values_02_logistics, "Logistics", "Logistics Employment Share", 202, emp_year, lgstc_emp_share, rank_lgstc_emp);
	%_append_category(values_02_logistics, "Logistics", "Commodity Flows per Capita (Rail)", 203, flows_year, rail_flows_per_capita, rank_rail_flows);
	%_append_category(values_02_logistics, "Logistics", "Commodity Flows per Capita (Road)", 204, flows_year, road_flows_per_capita, rank_road_flows);
	%_append_category(values_02_logistics, "Logistics", "Shipped Goods", 205, flows_year, score_shipping, rank_shipping);
	%_append_category(values_02_logistics, "Logistics", "Value of Shipped Goods (Subcategory)", 206, flows_year, ship_val, score_ship_val);
	%_append_category(values_02_logistics, "Logistics", "Tons of Shipped Goods (Subcategory)", 207, flows_year, ship_tons, score_ship_tons);
	%_append_category(values_02_logistics, "Logistics", "Ton-Miles of Shipped Goods (Subcategory)", 208, flows_year, ship_tonmiles, score_ship_tonmiles);
	%_append_multiyear_category(values_02_logistics, "Logistics", "State and Local Infrasturcture Expenditures", 209, hwy_start, hwy_end,avg_hwy_exp_perc, rank_hwy_exp);
	%_append_category(values_02_logistics, "Logistics", "Obligation of FHWA Funds per Capita (Federal)", 210, FHWA_year, federal_fhwa_funds, rank_fed_fhwa_funds);
	%_append_category(values_02_logistics, "Logistics", "Obligation of FHWA Funds per Capita (All Sources)", 211, FHWA_year, total_fhwa_funds, rank_tot_fhwa_funds);
	%_append_final_category(values_02_logistics, "Logistics", 299);

	
	/* ### 03_Human_Capital ### */
	
	%_append_category(values_03_human_capital, "Human Capital", "Percent with HS Diploma or Greater", 301, edu_att_yr, perc_hs_plus, rank_hs_plus);
	%_append_category(values_03_human_capital, "Human Capital", "Percent with Bachelor's Degree", 302, edu_att_yr, perc_bach_deg, rank_bach_deg);
	%_append_category(values_03_human_capital, "Human Capital", "First Year Retention Rate (CTC Colleges)", 303, ret_yr, retention_rate, rank_retention);
	%_append_category(values_03_human_capital, "Human Capital", "AA Graduation Rate", 304, aa_grad_yr, aa_grad_rate, rank_aa_grad);
	%_append_category(values_03_human_capital, "Human Capital", "Enrollment in Adult Basic Education", 305, adlt_edu_yr, adult_edu_enroll, rank_adult_edu);
	%_append_category(values_03_human_capital, "Human Capital", "Workers with AA", 306, aa_yr, perc_aa, rank_perc_aa);
	%_append_category(values_03_human_capital, "Human Capital", "8th Grade Math Scores", 307, math_scr_yr, math_scores, rank_math_scores);
	%_append_category(values_03_human_capital, "Human Capital", "High School Graduation Rate", 308, grad_rate_yr, grad_rate, rank_grad_rate);
	%_append_final_category(values_03_human_capital, "Human Capital", 399);


	/* ### 04_Benefits_Costs ### */

	%_append_category(values_04_benefits_costs, "Benefits Costs", "Health Care Premiums", 401, prem_year, rank_premium, rank_premium);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Health Care Single Premiums (Subcategory)", 402, prem_year, single_premium, single_prem_score);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Health Care Family Premiums (Subcategory)", 403, prem_year, family_premium, family_prem_score);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Long Term Health Care Costs", 404, long_costs_yr, rank_long_term_cost, rank_long_term_cost);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Assisted Living Costs (Subcategory)", 405, long_costs_yr, assisted_living_cost, assisted_living_score);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Nursing Home Costs (Subcategory)", 406, long_costs_yr, nursing_home_cost, nursing_home_score);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Worker's Compensation rates", 407, wc_year, wc_benefits, rank_wc_benefits);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Fringe Benefits Share of Wages", 408, fringe_year, fringe_ben_share, rank_fringe);
	%_append_category(values_04_benefits_costs, "Benefits Costs", "Federal Total Expenditures per Capita", 409, funds_year, fed_exp_per_capita, rank_fed_exp);
	%_append_final_category(values_04_benefits_costs, "Benefits Costs", 499)

	
	/* ### 05_Global_Position ### */

	%_append_category(values_05_global_position, "Global Position", "Manufacturing Exports per Capita", 501, exports_year, mfg_exp_per_capita, rank_exports);
	%_append_multiyear_category(values_05_global_position, "Global Position", "Manufacturing Exports Growth", 502, growth_from_year, growth_to_year, export_growth, rank_export_growth);
	%_append_category(values_05_global_position, "Global Position", "Personal Income per Capita Derived from Foreign-Owned Manufacturers", 503
			,PI_FOM_year, PCI_foreign_owned, rank_PCI_foreign);
	%_append_category(values_05_global_position, "Global Position", "Demand Adaptability Index", 504, adapt_year, demand_adaptability, rank_demand_adaptability);
	%_append_category(values_05_global_position, "Global Position", "Exports per Import", 505, exp_per_imp_year, exp_per_imp, rank_exp_per_imp);
	%_append_category(values_05_global_position, "Global Position", "Reexports per Capita", 506, reexp_year, reexp_per_capita, rank_reexp);
	%_append_final_category(values_05_global_position, "Global Position", 599);


	/* ### 06_Productivity_and_Innovation ### */
	
	%_append_multiyear_category(values_06_prod_and_innov, "Productivity and Innovation", "Growth in Manufacturing Value Added", 601
		,growth_from_year, growth_to_year, value_growth, rank_value_growth);
	%_append_category(values_06_prod_and_innov, "Productivity and Innovation", "Research and Development", 602, resdev_year, resdev_per_capita, rank_resdev);
	%_append_category(values_06_prod_and_innov, "Productivity and Innovation", "Patents per Capita", 603, patent_year, patents_per_capita, rank_patents);
	%_append_category(values_06_prod_and_innov, "Productivity and Innovation", "Manufacturing Productivity", 604, prod_year, mfg_productivity, rank_mfg_productivity);
	%_append_final_category(values_06_prod_and_innov, "Productivity and Innovation", 699);


	/* ### 07_Tax_Climate ### */

	%_append_category(values_07_fiscal_climate, "Tax Climate", "Corporate Tax Index", 701, tax_year, corp_tax_rank, corp_tax_rank);
	%_append_category(values_07_fiscal_climate, "Tax Climate", "Individual Income Tax Index", 702, tax_year, inc_tax_rank, inc_tax_rank);
	%_append_category(values_07_fiscal_climate, "Tax Climate", "Sales Tax Index", 703, tax_year, sales_tax_rank, sales_tax_rank);
	%_append_category(values_07_fiscal_climate, "Tax Climate", "Unemployment Insurance Tax Index", 704, tax_year, unemp_ins_tax_rank, unemp_ins_tax_rank);
	%_append_category(values_07_fiscal_climate, "Tax Climate", "Property Tax Index", 705, tax_year, property_tax_rank, property_tax_rank);
	%_append_final_category(values_07_fiscal_climate, "Tax Climate", 799);

	
	/* ### 08_Diversification ### */

	%_append_category(values_08_diversification, "Diversification", "Manufacturing Diversification (Herfindahl Index)", 801, diversity_year, Herfindahl_index, rank_diversification);
	%_append_final_category(values_08_diversification, "Diversification", 899);


	/* ### 09_Public_Financing ### */
	
	%_append_multiyear_category(values_09_public_financing, "Expected Fiscal Liability Gap", "Unfunded Liability per Capita", 901
		,liab_start_year, liab_end_year, unfunded_liab_per_capita, rank_liab_per_capita);
	%_append_multiyear_category(values_09_public_financing, "Expected Fiscal Liability Gap", "Unfunded Liability percent of Manufacturing GDP", 902
		,liab_start_year, liab_end_year, liability_per_mfg_gdp, rank_liab_per_mfg_gdp);
	%_append_multiyear_category(values_09_public_financing, "Expected Fiscal Liability Gap", "Average Benefits per Retiree", 903,
		liab_start_year, liab_end_year, avg_benefit, rank_avg_benefit);
	%_append_category(values_09_public_financing, "Expected Fiscal Liability Gap", "S&P Bond Rating", 904, rating_year, rank_bond_rating, rank_bond_rating);
	%_append_final_category(values_09_public_financing, "Expected Fiscal Liability Gap", 999)


	/* ######################### */
	/* ### Add Overall Ranks ### */
	/* ######################### */

	proc sql;
		create table avg_ranks as
		select distinct state, "Overall Ranking" as Category, "Overall Ranking" as Subcategory, 9999 as sort_order,
			"N/A" as new_year, avg(new_stat) as new_stat,
			"N/A" as old_year, avg(old_stat) as old_stat
		from details
		where Subcategory = "Final Results"
		group by state
		;
	quit;

	proc rank ties=low
		data = avg_ranks
		out = avg_ranks;
		var new_stat old_stat;
		ranks new_rank old_rank;
	run;

	proc sql;
		create table details as
		select state, category, subcategory, sort_order, new_year, new_stat, new_rank, old_year, old_stat, old_rank
		from details
		union		
		select state, category, subcategory, sort_order, new_year, new_stat, new_rank, old_year, old_stat, old_rank
		from avg_ranks
		;
	quit;


	/* ######################### */
	/* ### Add Letter Grades ### */
	/* ######################### */

	proc sql;
		create table details as
		select d.*, new.grade as new_grade, old.grade as old_grade
		from details d
		inner join shared.grades new
		on d.new_rank = new.rank
		inner join shared.grades old
		on d.old_rank = old.rank
		;
	quit;


	/* ################## */
	/* ### Clean Data ### */
	/* ################## */

	proc sql;
		create table details as
		select * from details
		order by state, sort_order
		;
	quit;


	/* ################### */
	/* ### Output Data ### */
	/* ################### */

	data out.All_details;
		retain
			State Category Subcategory sort_order
			new_year new_stat new_rank new_grade
			old_year old_stat old_rank old_grade
			;
		set details;
	run;

	proc export
		data=out.all_details
		outfile="&rootpath.&curr_fldr.\Summaries\Aggregate\_details_&curr_year..csv"
		dbms=csv
		replace;
	run;

%mend create_detailed_summary;


/* A helper macro that appends one subcategory of data to the details table */
%macro _append_category(dataset, category, subcategory, sort_order, year_id, stat_id, rank_id);
	
	proc sql;
		create table details as
		select * from details
		union
		select new.state, &category as Category, &subcategory as Subcategory, &sort_order as sort_order
			,cat(new.&year_id,"") as new_year, new.&stat_id as new_stat, new.&rank_id as new_rank
			,cat(old.&year_id,"") as old_year, old.&stat_id as old_stat, old.&rank_id as old_rank
		from out.&dataset new
		inner join
		out_old.&dataset old
		on new.fips = old.fips
		;
	quit;

%mend _append_category;

/* A helper macro that appends one subcategory of data to the details table for multi-year data rows */
%macro _append_multiyear_category(dataset, category, subcategory, sort_order, begin_id, end_id, stat_id, rank_id);
	
	proc sql;
		create table details as
		select * from details
		union
		select new.state, &category as Category, &subcategory as Subcategory, &sort_order as sort_order
			,cat(new.&begin_id,"-",new.&end_id) as new_year, new.&stat_id as new_stat, new.&rank_id as new_rank
			,cat(old.&begin_id,"-",old.&end_id) as old_year, old.&stat_id as old_stat, old.&rank_id as old_rank
		from out.&dataset new
		inner join
		out_old.&dataset old
		on new.fips = old.fips
		;
	quit;

%mend _append_multiyear_category;

/* A helper macro that appends the final category score to the details table */
%macro _append_final_category(dataset, category, sort_order);
	
	proc sql;
		create table details as
		select * from details
		union
		select new.state, &category as Category, "Final Results" as Subcategory, &sort_order as sort_order
			,"N/A" as new_year, new.score_final as new_stat, new.rank_final as new_rank
			,"N/A" as old_year, old.score_final as old_stat, old.rank_final as old_rank
		from out.&dataset new
		inner join
		out_old.&dataset old
		on new.fips = old.fips
		;
	quit;

%mend _append_final_category;
