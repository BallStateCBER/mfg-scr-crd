libname shared "C:\Users\bjpatterson\Box Sync\CBER Box\CBER Box - Research\00 - Recurring Studies\Mfg Scorecard\SAS_Shared_Data";

proc import
	datafile="C:\Users\bjpatterson\Box Sync\CBER Box\CBER Box - Research\00 - Recurring Studies\Mfg Scorecard\SAS_Shared_Data\bond_rating_scale.csv"
	out=shared.bond_rating_scale
	dbms=csv
	replace
	;
	guessingrows=10000;
run;
