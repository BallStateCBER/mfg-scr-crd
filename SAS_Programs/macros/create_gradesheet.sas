/*
#############################################################################
Objective:
	Given a dataset with rank data columns:
		Calculate the average of all ranks:
		Calculate the final ranking (ranking of average)
		Assign letter grades to ranks
	
	PARAMS:
		ranked_data: the table containing rank data
		gradesheet_name: the name of the destination table for letter grade outputs

	OUTPUTS:
		adds 'score_final' and 'rank_final' columns the the ranked_data dataset
		a table is created (gradesheet_name) with fips, state name, rank, and letter grade data

Author:
	Brandon Patterson
Notes:
	Only
		(may need to be reworked if data ever becomes more granular)

#############################################################################
*/

/* (for testing)
%let ranked_data = productivity_data;
%let gradesheet_name = productivity_grades;
%put &ranked_data;
%put &gradesheet_name;
*/

%macro create_gradesheet(ranked_data, gradesheet_name);

	/* Gather all of the 'rank' column names (before calculating overall rank) */
	%get_column_names_matching_regex(
		table=&ranked_data
		,regex='/[Rr][Aa][Nn][Kk]/'
		,out=temp_rank_cols
	);

	/* Get all rank columns (individual categories) */
	proc sql noprint;
		select name
		into :rank_cols separated by ' '
		from temp_rank_cols
		;
	quit;

	/* Calculate an average score (average of all ranks) */
	data &ranked_data;
		set &ranked_data;
		score_final = Mean(of &rank_cols);
	run;

	/* Determine final rank based on the average */
	proc rank ties=low
		data = &ranked_data
		out=&ranked_data;
		var score_final;
		ranks rank_final;
	run;

	/* Add rank_final to the list of rank columns */
	proc sql;
		insert into temp_rank_cols
		set name='rank_final'
		;
	quit;

	/* This is an ugly bit of code that builds the complex parts of the sql query that assigns letter grades */
	proc sql noprint;
		select 
			cat(strip(name), ', ', strip(name), '_grade.grade as ', strip(tranwrd(name,'rank','grade')))
			,cat('inner join shared.grades ', strip(name), '_grade on ', %unquote(%str(%'&ranked_data%')), '.', strip(name), ' = ', strip(name), '_grade.rank')
		into
			:fields separated by ', '
			,:join_text separated by ' '
		from temp_rank_cols
		;
	quit;

	/* Map each rank column to a letter grade, and extract the data to the destination table */
	proc sql;
		create table &gradesheet_name.
		as select
			fips, state, &fields.
		from
		&ranked_data.
		&join_text.
		;
	quit;

	proc sort data=&gradesheet_name.;
		by fips;
	run;
		

%mend create_gradesheet;
