/*
#############################################################################
Objective:
	Create the current year gradesheet (letter grades only)

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

#############################################################################
*/

%macro output_final_gradesheet;

	/* ######################### */
	/* ### Create Gradesheet ### */
	/* ######################### */

	proc sql;
		create table gradesheet as
		select
			g1.state
			,g1.grade_final as manf_grd
			,g2.grade_final as lgstc_grd
			,g3.grade_final as hmn_cptl_grd
			,g4.grade_final as bnfts_grd
			,g5.grade_final as glbl_pos_grd
			,g6.grade_final as prod_grd
			,g7.grade_final as tax_grd
			,g8.grade_final as dvrs_grd
			,g9.grade_final as fscl_grd
		from out.grades_01_manufacturing g1
		inner join out.grades_02_logistics g2
			on g1.fips = g2.fips
		inner join out.grades_03_human_capital g3
			on g1.fips = g3.fips
		inner join out.grades_04_benefits_costs g4
			on g1.fips = g4.fips
		inner join out.grades_05_global_position g5
			on g1.fips = g5.fips
		inner join out.grades_06_prod_and_innov g6
			on g1.fips = g6.fips
		inner join out.grades_07_fiscal_climate g7
			on g1.fips = g7.fips
		inner join out.grades_08_diversification g8
			on g1.fips = g8.fips
		inner join out.grades_09_public_financing g9
			on g1.fips = g9.fips
		order by state
			;
	quit;

	/* ######################### */
	/* ### Add Pretty Labels ### */
	/* ######################### */

	data gradesheet;
		set gradesheet;
		label
			state="State"
			manf_grd="Manufacturing"
			lgstc_grd="Logistics"
			hmn_cptl_grd="Human Capital"
			bnfts_grd="Benefits Costs"
			glbl_pos_grd="Global Position"
			prod_grd="Productivity and Innovation"
			tax_grd="Tax Climate"
			dvrs_grd="Diversification"
			fscl_grd="Expected Fiscal Liability Gap"
			;
	run;


	/* ######################### */
	/* ### Output Gradesheet ### */
	/* ######################### */

	data Out.Final_grades;
		set gradesheet;
	run;

	proc export
		data=gradesheet
		outfile="&rootpath.&curr_fldr.\Summaries\Aggregate\gradesheet_&curr_year..csv"
		label
		dbms=csv
		replace;
	run;

%mend output_final_gradesheet;
