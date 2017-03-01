/*
#############################################################################
Objective:
	Make sure that the expected folder structure exists for the current manufacturing scorecard

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

#############################################################################
*/

%macro setup_summary_folders;

	/* Ensure "Summaries" folder exists */
	libname new	%unquote(%str(%'&rootpath.&curr_fldr.\Summaries%'));
	libname new clear;

	/* create aggregate output folder */
	libname new %unquote(%str(%'&rootpath.&curr_fldr.\Summaries\Aggregate%'));
	libname new clear;

	/* create state output folders */
	proc sql noprint;
		select cat('libname new	"&rootpath.&curr_fldr.\Summaries\', state, '"; libname new clear;')
		into :create_state_fldrs separated by ' '
		from shared.state_fips
		;
	quit;

	&create_state_fldrs;

%mend setup_summary_folders;
