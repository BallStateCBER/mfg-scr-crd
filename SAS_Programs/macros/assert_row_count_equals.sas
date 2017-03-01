/*
#############################################################################
Objective:
	Add facilties for asserting that a dataset has a particular length
	(Useful for making sure rows aren't missing after an operation)

Author:
	Brandon Patterson

Notes:
	Terminates the current run if the dataset is the wrong size.
	Only use this if you want badly shaped data to halt calculations.

#############################################################################
*/

%macro assert_row_count_equals(table, number);

	proc sql noprint;
		select distinct count(fips)
		into :rows
		from &table
		;
	quit;

	%if %sysevalf(&rows ^= &number) %then %do;
		data _null_;
			put "ASSERTION ERROR: Table &table has &rows rows instead of &number!";
			put 'Aborting...';
			abort cancel; /* stop processing so that we can address the error! */ 
		run;
	%end;

%mend assert_row_count_equals;
