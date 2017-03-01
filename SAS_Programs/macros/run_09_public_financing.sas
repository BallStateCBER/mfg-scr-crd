/*
#############################################################################
Objective:
	Synthesize Manufacturing Diversification inputs into grades
	(Replaces the `09 Public Financing 20xx.xlsx` workbook)

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

%macro run_09_public_financing;

	/* ############################ */
	/* ### Make Empty Scorecard ### */
	/* ############################ */

	proc sql;
		create table liability_data as
		select fips, state
		from shared.state_fips
		;
	quit;

	%assert_row_count_equals(liability_data, 50);

	/* ##################################### */
	/* ### Unfunded Liability per Capita ### */
	/* ##################################### */

	%get_data(census, popset);
	%ensure_numeric(popset, year);
	%ensure_numeric(popset, fips);
	%ensure_numeric(popset, popest);

	%get_data(BLS, CPI);
	%ensure_numeric(CPI, year);
	%ensure_numeric(CPI, fips);
	%ensure_numeric(CPI, Jun_adj_CPI)

	
	%get_data(PublicPlansData, Unfunded_Liabilities);
	%ensure_numeric(Unfunded_Liabilities, year);
	%ensure_numeric(CPI, fips);
	%ensure_numeric(Unfunded_Liabilities, uaal_gasb);
	%ensure_numeric(Unfunded_Liabilities, beneficiaries_tot);
	%ensure_numeric(Unfunded_Liabilities, expense_TotBenefits);

	/* throw out incomplete "recent" data (empty values in the most recent year throw off the calculations) */
	proc sql;
		create table Unfunded_liabs_clean
		as select * from Unfunded_Liabilities
		where uaal_gasb ^= 0
			and beneficiaries_tot ^= 0
			and expense_TotBenefits ^= 0
		;
	quit;

	/* get latest year of data for each plan (individually) */
	proc sql;
		create table latest_liabilities as
		select *
		from unfunded_liabs_clean
		group by state, PlanName
		having year = max(year)
		;
	quit;

	/* adjust data to a common inflation year */
	proc sql;
		create table cpi_adjustor as
		select year, max(Jun_adj_CPI)/Jun_adj_CPI as adjustor
		from cpi
		;
	quit;

	proc sql;
		create table latest_liabilities as
		select l.PlanName, l.state, l.fips, l.year
			,l.uaal_gasb * c.adjustor as uaal_gasb
			,l.beneficiaries_tot
			,l.expense_totbenefits * c.adjustor as expense_totbenefits
		from latest_liabilities l
		inner join cpi_adjustor c
		on l.year = c.year
		;
	quit;
	
	/* Sum up the liabilities by state */
	proc sql;
		create table latest_liabilities_sum as
		select distinct state, fips
			,min(year) as liab_start_year
			,max(year) as liab_end_year
			,sum(uaal_gasb) as uaal_gasb
			,sum(beneficiaries_tot) as beneficiaries_tot
			,sum(expense_totbenefits) as expense_totbenefits
		from latest_liabilities
		group by state
		;
	quit;

	/* Add Unfunded Liability per Capita to the liability data */
	proc sql;
		create table liability_data as
		select d.*, l.liab_start_year, l.liab_end_year, l.uaal_gasb/p.popest*1000 as Unfunded_liab_per_capita
		from liability_data d
		inner join latest_liabilities_sum l
			on d.fips = l.fips
		inner join popset p
			on l.fips = p.fips
		having p.year = max(p.year)
		;
	quit;

	%assert_row_count_equals(liability_data, 50);


	/* ####################################################### */
	/* ### Unfunded Liability per GDP (Manufacturing only) ### */
	/* ####################################################### */

	/* latest_liabilities_sum table created above */

	%get_data(bea, gdp_curr);
	%ensure_numeric(gdp_curr, year);
	%ensure_numeric(gdp_curr, LineCode);
	%ensure_numeric(gdp_curr, gdp_curr);

	proc sql;
		create table liability_data as
		select d.*, l.uaal_gasb/g.gdp_curr/1000 as liability_per_mfg_gdp
		from liability_data d
		inner join latest_liabilities_sum l
			on d.fips = l.fips
		inner join gdp_curr g
			on l.fips = g.fips and l.liab_end_year = g.year
		where g.desc = "Manufacturing"
		order by d.fips
		;
	quit;

	%assert_row_count_equals(liability_data, 50);


	/* ########################################## */
	/* ###### Average Benefits per Retiree ###### */
	/* ########################################## */

	/* latest_liabilities created in a previous step */
	/* cpi_adjustor created in a previous step */

	proc sql;
		create table liability_data as
		select d.*, l.expense_totbenefits/l.beneficiaries_tot as avg_benefit
		from liability_data d
		inner joing latest_liabilities_sum l
			on d.fips = l.fips
		;
	quit;

	%assert_row_count_equals(liability_data, 50);


	/* ############################# */
	/* ###### S&P Bond Rating ###### */
	/* ############################# */

	%get_data(S_and_P, bond_ratings);
	%get_latest_data(bond_ratings, latest_bond_rating);

	proc sql;
		create table latest_bond_rating as
		select l.*, s.numeric as bond_rank
		from latest_bond_rating l
		inner join shared.bond_rating_scale s
		on l.rating = s.rating
		;
	quit;

	proc sql;
		create table liability_data as
		select d.*, b.year as rating_year, b.rating as Rating, b.bond_rank as bond_rating_score
		from liability_data d
		inner join latest_bond_rating b
		on d.fips = b.fips
		;
	quit;

	%assert_row_count_equals(liability_data, 50);


	/* ########################### */
	/* ###### Finalize Data ###### */
	/* ########################### */

	/* Calculate Individual Category Ranks */
	proc rank ties=low /* (Low is Good) */
		data = liability_data
		out = liability_data;
		var 
			unfunded_liab_per_capita
			liability_per_mfg_gdp
			/*liability_per_tot_gdp*/
			bond_rating_score
			;
		ranks
			rank_liab_per_capita
			rank_liab_per_mfg_gdp
			/*rank_liab_per_tot_gdp*/
			rank_bond_rating
			;
	run;

	%assert_row_count_equals(liability_data, 50);

	proc rank descending ties=low /* (High is Good) */
		data = liability_data
		out = liability_data;
		var avg_benefit;
		ranks rank_avg_benefit;
	run;

	%assert_row_count_equals(liability_data, 50);


	/* Calculate Grades */
	%create_gradesheet(liability_data, liability_grades);
	%assert_row_count_equals(liability_grades, 50);

	/* ############################## */
	/* ###### Output Final Data ##### */
	/* ############################## */

	data out.values_09_Public_Financing;
		set liability_data;
		attrib _all_ label=" ";
	run;

	data out.grades_09_Public_Financing;
		set liability_grades;
		attrib _all_ label=" ";
	run;

	%clr_lib();

%mend run_09_public_financing;
