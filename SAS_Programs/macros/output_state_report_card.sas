/*
#############################################################################
Objective:
	Create the report card for an individual state (overall grades only)

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

#############################################################################
*/

*%let state = Alabama;

%macro output_state_report_card(state);

	/* ################################# */
	/* ### Create Overall Gradesheet ### */
	/* ################################# */

	proc sql;
		create table state_grades as
		select Category
			,new_stat, new_rank, new_grade
			,old_stat, old_rank, old_grade
		from out.all_details
		where State = "&state" and (subcategory = "Final Results" or subcategory = "Overall Ranking")
		order by sort_order
		;
	quit;


	/* ######################### */
	/* ### Add Pretty Labels ### */
	/* ######################### */

	data state_grades;
		set state_grades;
		label
			category="Subject"
			new_stat="Average Score &curr_year"
			new_rank="Rank &curr_year."
			new_grade="Grade &curr_year"
			old_stat="Average Score &prev_year"
			old_rank="Rank &prev_year."
			old_grade="Grade &prev_year"
			;
	run;

	
	/* ################################# */
	/* ### Output Overall Gradesheet ### */
	/* ################################# */
	
	%let state_name = %sysfunc(tranwrd(&state,%str( ),_));

	proc export
		data=state_grades
		outfile="&rootpath.&curr_fldr.\Summaries\&state.\Report_Card_&curr_year._&state_name..csv"
		label
		dbms=csv
		replace;
	run;


%mend output_state_report_card;
