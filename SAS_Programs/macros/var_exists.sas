/*
Example taken from http://www.sascommunity.org/wiki/Tips:Check_if_a_variable_exists_in_a_dataset

Usage:
%put %var_exists(sashelp.class,name);
%put %var_exists(sashelp.class,aaa);
*/

%macro var_exists(ds,var);
	%local rc dsid result;
	%let dsid=%sysfunc(open(&ds));
	%if %sysfunc(varnum(&dsid,&var)) > 0 %then %do;
		%let result=1;
		%put NOTE: Var &var exists in &ds;
	%end;
	%else %do;
		%let result=0;
		%put NOTE: Var &var not exists in &ds;
	%end;
	%let rc=%sysfunc(close(&dsid));
	&result
%mend var_exists;
