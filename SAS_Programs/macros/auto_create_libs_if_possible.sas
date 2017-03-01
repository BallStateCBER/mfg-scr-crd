/*
#############################################################################
Objective:
	If SAS version is 9.3+, enable the automatic creation of library folders.

Author:
	Brandon Patterson

Notes:
	(If running SAS 9.2 or earlier, library folders still have to be set up manually.)
#############################################################################
*/

%macro auto_create_libs_if_possible;
	%if %sysevalf(&SYSVER >= 9.3) %then %do;
		options dlcreatedir;
	%end;
%mend auto_create_libs_if_possible;
