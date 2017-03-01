/*
#############################################################################
Objective:
	Delete all datasets in a given library.
	(Use to clean up the Work folder after saving final calculations somewhere else.)

Author:
	Brandon Patterson

Notes:
	

#############################################################################
*/

%macro clr_lib(library=work);
	
	/* Delete all tables in the given folder */
	proc datasets
		nolist
		lib=&library.
		kill;
	quit;
	run;
%mend crl_lib;
