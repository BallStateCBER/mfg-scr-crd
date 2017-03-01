/*
Code Owners: Brandon Patterson

Purpose:
	Utility for selecting column names out of a table that match a given regular expression

Notes: 
	
*/

%macro get_column_names_matching_regex(
		table=/* The name of the dataset to investigate */
		,regex=/* A perl regex to match against */
		,out=/* Where to store the table of column names */
	);

	proc sql;
		create table &out. as
		select name
		from dictionary.columns
		where
			upper(memname) = upper(%unquote(%str(%'&table%')))
		and
			prxmatch(&regex.,name)
		;
	quit;
%mend;
