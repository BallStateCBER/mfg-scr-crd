/*
#############################################################################
Objective:
	Given a table and column, make sure the column contains numeric data, and set nulls to zero.
	
	PARAMS:
		table: the table to check (will be replaced by a new table of the same name with numeric data
		column: the column that is desired to be numeric

Author:
	Brandon Patterson

Notes:

#############################################################################
*/

%macro ensure_numeric(table, column);

	data &table.;
		set &table;
		&column = prxchange('s/[\$, ]//', -1, &column.); /* remove '$', ',' and ' ' from strings */
	run;

	data &table.;
		set &table.;
		&column._num = input(&column., 15.); /* Convert character column to numeric */
		if missing(&column._num) then &column._num = 0; /* set nulls to zero */
	run;

	data &table.;
		set &table.(drop = &column.);
		rename &column._num=&column.; /* Rename numeric column to original name */
	run;

%mend ensure_numeric;
