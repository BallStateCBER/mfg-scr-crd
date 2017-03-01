/*
#############################################################################
Objective:
	Runs the Manufacturing Scorecard SAS code from a central location.
	(Replaces the previous excel-driven process to increase efficiency and reduce errors)

Author:
	Brandon Patterson

Notes:
	IMPORTANT!!! Make sure to update macro variables at the top of this file (line ~20)!

#############################################################################
*/

/* ############################################# */
/* ## SET THESE VARIABLES TO RUN THE PROGRAM! ## */
/* ############################################# */

/* (This changes every year) */
%let curr_year=2017;

/* (These will probably never change) */
%let prev_year = %eval(&curr_year.-1);
*%let prev_year = &curr_year; /* for testing purposes */

%let curr_fldr=Scorecard_&curr_year._SAS;
%let prev_fldr=Scorecard_&prev_year._SAS;

%let sas_fldr = SAS_Programs;

%put current year folder = &curr_fldr;
%put previous year folder = &prev_fldr;


/* ############################################# */
/* ######## SET UP ENVIRONMENT TO RUN ########## */
/* ############################################# */

/*	GET ROOT DIRECTORY ; */

%let rootpath = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, %length(%sysget(SAS_EXECFILEPATH))-%length(&sas_fldr.\%sysget(SAS_EXECFILEname)));
%put &= rootpath;

/* get the location of the macro files*/
filename macros %unquote(%str(%'&rootpath.&sas_fldr.\macros%'));

/* IMPORT MACROS */
option sasautos=(macros sasautos);
%auto_create_libs_if_possible;

/* SET UP LIBRARIES */
libname out %unquote(%str(%'&rootpath.&curr_fldr.\SAS_Outputs%')); /* for data outputs */
libname out_old %unquote(%str(%'&rootpath.&prev_fldr.\SAS_Outputs%')); /* for comparison*/

libname shared %unquote(%str(%'&rootpath.SAS_Shared_Data%')); /* for shared data that never changes (fips codes, etc) */


/* ############################################# */
/* ############ RUN SCORECARD CODE ############# */
/* ############################################# */

/*
	Once you've run the setup code above:
	Highlight the commands below that you wish to run, and hit F3 to execute them
	(This is done to prevent accidental full runs.)
*/

/*
%run_01_manufacturing();
%run_02_logistics();
%run_03_human_capital();
%run_04_benefits_costs();
%run_05_global_position();
%run_06_prod_and_innov();
%run_07_fiscal_climate();
%run_08_diversification();
%run_09_public_financing();
%run_90_summarize_data();
%run_91_state_details();
%run_92_change_summary();
*/
