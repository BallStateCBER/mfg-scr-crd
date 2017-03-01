/*
#############################################################################
Objective:
	Scrub a dataset so that it has:
		Consistent state naming conventions fips codes and state names
		Only State-level data
	
	PARAMS:
		data: the table to be scrubbed

Author:
	Brandon Patterson

Notes:
	Assumes the existence of a "fips" column
	Replaces the original dataset with the scrubbed one
	(Depends on shared data being preloaded, see MAIN.sas setup-code)

#############################################################################
*/

%macro scrub_state_data(data);
	
	/* Detect data structure and fill in missing data */
	%if %var_exists(&data, fips) %then %do;

		/* Scrub any trailing zeros from fips codes */
		data &data.;
			set &data;
			fips = prxchange('s/000$//', 1, fips);
		run;

		%if not %var_exists(&data, state) %then %do;
			/* fips exists, state does not */
			proc sql;
				create table &data as
				select &data..*, lookup.state
				from &data
				inner join shared.state_fips lookup
				on &data..fips = lookup.fips
				;
			quit;
		%end;
	%end;
	%else %if %var_exists(&data, state) %then %do;
		/* no fips, but state names exist */

		/* Scrub state names to clean up some common formatting problems */
		data &data.;
			set &data;
			state = strip(prxchange('s/[^A-Z\s]*//i', -1, state));
		run;

		proc sql;
			create table &data. as
			select &data..*, lookup.fips
			from &data
			inner join shared.state_fips lookup
			on upper(&data..state) = upper(lookup.state)
			;
		quit;
	%end;
	%else %if %var_exists(&data, code) %then %do;
		/* no fips, no name, but state code exists */
		proc sql;
			create table &data. as
			select &data..*, lookup.fips, lookup.state
			from &data
			inner join shared.state_fips lookup
			on upper(&data..code) = upper(lookup.code)
			;
		quit;
	%end;

	/* Remove any remaining non-state data rows */
	proc sql;
		create table &data.
		as select &data..*
		from
			&data.
		inner join
			shared.state_fips
		on
			state_fips.fips = &data..fips
		;
	quit;

%mend scrub_state_data;
