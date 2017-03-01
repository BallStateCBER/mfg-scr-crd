/*
#############################################################################
Objective:
	Combines Manufacturing Scorecard Data into summary files

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! This code cannot be run without running the setup code at the top of `MAIN.sas`

#############################################################################
*/

%macro run_90_summarize_data;

	%setup_summary_folders();
	%output_final_gradesheet();
	%create_detailed_summary();

	/* generate overall state report cards */
	proc sql noprint;
		select
			cat('%output_state_report_card(', state, ');')
		into :run_state_cards separated by ' '
		from shared.state_fips
		;
	quit;

	&run_state_cards;

	%clr_lib();


%mend run_90_summarize_data;
