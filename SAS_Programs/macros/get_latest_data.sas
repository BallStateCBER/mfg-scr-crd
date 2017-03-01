/*
#############################################################################
Objective:
	Filter a dataset down to only the most recent year of data
	Data is filtered by the most recent year for any state.
	(May not work as intended with mixed year data between states.)
	
	PARAMS:
		raw_data: a table containing data to be filtered
		destination: the name for the filtered table
		num_years: (optional) the number of years

Author:
	Brandon Patterson

Notes:
	Assumes the existence of a "fips" column
		(should be introduced during the initial data cleaning steps)
	Assumes the existence of a "Year" column
		(may need to be reworked if data ever becomes more granular)

#############################################################################
*/

%macro get_latest_data(raw_data, destination, num_years=1);

	/* find the most recent data year, and save it to a macro variable */
	proc sql noprint;
		select distinct max(year)
		into :latest_year
		from &raw_data.
		;
	quit;
	
	/* delete any data older than the desired number of years */
	data &destination.;
		set &raw_data.;
		if &latest_year. - year >= &num_years. then delete;
	run;

%mend get_latest_data;
