/*
#############################################################################
Objective:
	Output some metadata that shows what's changed (and what hasn't changed).
	This should help verify that we're using current and reasonably accurate data.

Author:
	Brandon Patterson

Notes:
		IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`
		as well as all the individual scorecards, and `run_90_summarize_data`

#############################################################################
*/

%macro run_92_change_summary();

	/* Make a list of stale data (so that we know what still needs to be updated */
	
	data stale_categories(keep= Category Subcategory data_year);
		set out.all_details;
		where State = "Indiana"
			and new_year = old_year
			and new_year ^= "N/A"
			;
		Data_Year=new_year;	
	run;

	proc export
		data=stale_categories
		outfile="&rootpath.&curr_fldr.\Summaries\Aggregate\_stale_data_&curr_year..csv"
		dbms=csv
		replace
		;
	run;


	/* Make a list of ~big changes to the data (to catch potential data issues */

	data changes(keep= State Category Subcategory new_stat old_stat percent_change rank_change);
		set out.all_details;
		percent_change = (new_stat - old_stat)/old_stat;
		rank_change = old_rank - new_rank;
		format percent_change percent7.2;
	run;

	proc export
		data=changes
		outfile="&rootpath.&curr_fldr.\Summaries\Aggregate\_changes_&curr_year..csv"
		dbms=csv
		replace
		;
	run;

	data changes(drop = new_stat old_stat);
		set changes;
		abs_percent_change = abs(percent_change);
		abs_rank_change = abs(rank_change);
	run;

	proc sql;
		create table change_summary as
		select distinct
			category
			,subcategory
			,avg(percent_change) as average_percent_change
			,avg(abs_percent_change) as average_abs_percent_change
			,min(percent_change) as min_change
			,max(percent_change) as max_change
			,min(rank_change) as min_rank_change
			,max(rank_change) as max_rank_change
			,sum(abs_rank_change)/50 as average_rank_shift
		from changes
		group by category, subcategory
		order by average_abs_percent_change descending 
		;
	quit;

	data change_summary;
		set  change_summary;
		format
			average_percent_change percent7.2
			average_abs_percent_change percent7.2
			min_change percent7.2
			max_change percent7.2
			;
	run;
	
	proc export
		data=change_summary
		outfile="&rootpath.&curr_fldr.\Summaries\Aggregate\_change_summary_&curr_year..csv"
		dbms=csv
		replace
		;
	run;

	%clr_lib();	

%mend run_92_change_summary;
