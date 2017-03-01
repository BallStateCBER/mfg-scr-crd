/*
#############################################################################
Objective:
	Combines Manufacturing Scorecard Data into state-specific summary files

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running 'MAIN.sas' and %run_90_summarize_data()
	(This code takes a while to run, because it creates ~500 individual files
	
#############################################################################
*/


%macro run_91_state_details;

/* generate individual category cards */
	proc sql noprint;
		select cat('%output_category_card(',TRIM(state),');')
		into :run_category_cards separated by ' '
		from shared.state_fips
		;
	quit;

	&run_category_cards;

	%clr_lib();


%mend run_91_state_details;
