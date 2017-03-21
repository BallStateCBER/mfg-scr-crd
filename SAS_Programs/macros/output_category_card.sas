/*
#############################################################################
Objective:
	Given a state name, construct and output the detailed gradesheet to the appropriate location

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

#############################################################################
*/


%macro output_category_card(state);
	
	/* ######################### */
	/* ### Create Gradesheet ### */
	/* ######################### */

	proc sql;
		create table cat_grades as
		select category, subcategory
			,new_year, new_stat, new_rank, new_grade
			,old_year, old_stat, old_rank, old_grade
			,new_stat-old_stat as diff, (new_stat-old_stat)/old_stat as pctchg
		from out.all_details
		where state = "&state."
		order by sort_order
		;
	quit;


	/* ######################### */
	/* ### Add Pretty Labels ### */
	/* ######################### */

	data cat_grades;
		set cat_grades;
		label
			category="Subject"
			new_year="Data Year &curr_year"
			new_stat="Score &curr_year"
			new_rank="Rank &curr_year."
			new_grade="Grade &curr_year"
			old_year="Data Year &prev_year"
			old_stat="Score &prev_year"
			old_rank="Rank &prev_year."
			old_grade="Grade &prev_year"
			diff="Difference &curr_year - &prev_year"
			pctchg="Percent change &curr_year - &prev_year"
			;
	run;

	
	/* ######################### */
	/* ### Output Gradesheet ### */
	/* ######################### */
	%let state_name = %sysfunc(tranwrd(&state,%str( ),_));
	
	proc export
		data=cat_grades
		outfile="&rootpath.&curr_fldr.\Summaries\&state.\Grade_Details_&curr_year._&state_name..csv"
		label
		dbms=csv
		replace
		;
	run;
	
%mend output_category_card;
