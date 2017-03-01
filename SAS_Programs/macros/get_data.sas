/*
#############################################################################
Objective:
	Reads raw data from the designated csv, placing it into a table by the same name
	Scrubs the data into a consistent format
	
	PARAMS:
		folder: the relative folder where the data file lives (from the SAS_inputs space)
		dataset: the file name (with no extension) of the dataset

	USAGE EXAMPLE:
		%get_raw_data(Census, Popset);

Author:
	Brandon Patterson

Notes:
	(Depends on shared data being preloaded, see MAIN.sas setup-code)

#############################################################################
*/

%macro get_data(folder, dataset);

	/* Import the raw data */
	proc import
		datafile="&rootpath.&curr_fldr.\SAS_inputs\&folder.\&dataset..csv"
		out=&dataset
		dbms=csv
		replace
		;
		guessingrows=10000;
	run;

	/* scrub the data for consistency */
	%scrub_state_data(&dataset);

%mend get_data;
