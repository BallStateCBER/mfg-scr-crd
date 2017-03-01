
CBER Manufacturing Scorecard, Implemented in SAS

Author: Brandon Patterson

Purpose: to standardize and simplify the old Excel-driven scorecard process
	 (to increase consistency, and reduce human error)



##############################
###  HOW TO RUN THIS CODE  ###
##############################

	1. Set up a new scorecard space
		a. Create a new scorecard folder, following old naming conventions exactly
		b. Copy in raw data from the previous year.
		c. If running SAS 9.2 or older:
			Copy the file structure in `_Scorecard_Template`.
		   If running SAS 9.3 or newer:
			SAS will create the file structure for you.

	2. Collect any new data that is available (see `Data Collection with SAS Process.docx`)


	3. Run the Scorecard (details in `How to Run SAS Scorecard.docx`)
		a. Update the variables at the top of `MAIN.SAS` to reflect the year you wish to run
		b. Run `Main.sas` to set up SAS for a full run
		c. Near the bottom of `Main.sas`, select the desired lines, named `%run_*`, and run
			(For a full run, highlight everything in this list.)

	4. Check outputs for reasonableness
		a. In the `Summaries\Aggregate` folder, there are some useful files for this purpose.
			Use `_stale_data_*.csv` to see which data hasn't been changed since last year
			Use `_change_summary_*.csv` to see an overview of which categories saw the biggest changes
			Use `_details_*.csv` to see detailed info about each category for each state

	5. Troubleshoot problems, and repeat steps 2-4 as needed.



#################################
###  HOW TO UPDATE THIS CODE  ###
#################################



IMPORTANT!: If you plan to update this code, please make sure to update the GitHub repository.
	Code changes in Box are not tracked by GitHub



The vast majority of this code uses the `proc SQL` command.
If you need help to understand these commands, ask a webdev (they should be fluent in SQL).



In general, a few steps are needed to add (or remove) a category from the Manufacturing Scorecard:

	1. Collect any new data required for the change.
		a. Put this data in an appropriate folder in the `Raw Data` folder for the current year

	2. Open the corresponding macro for the portion of the scorecard that you're updating.
	
	3. In an appropriate location among the other calculations:
		a. import any new data into SAS
		b. perform any calculations needed
		c. add the new data to the category dataset `{category}_data`

	4. Near the bottom of the same macro, make sure to edit the FINALIZE DATA section
		a. make sure to add/remove any categories to the rank calculations as needed
		b. (the SAS code assumes that anything with "rank" in the name is a graded category!)

	5. In `create_detailed_summary.sas`, add/remove lines to make sure changes show up in the results
		a. (Should be VERY similar to existing lines, with edits to subcategory, sort order, etc.)


An Example:

	Say we have a new "Cool Factor" that we've calculated,
	and we'd like to add it to the Global Position Scorecard.

	The following steps should add the new data into the process:


	1. Save the new data in the `SAS_Inputs` folder of a test project (we'll use `SAS_Inputs\Custom\coolness.csv`)


	2. In `macros\run_05_global_position`, make the following changes:
	
		a. In the ~middle section of code, add a new section for "Cool-Factor"

			Suggested Code:

			```
			/* ################### */
			/* ### Cool-Factor ### */
			/* ################### */

			%get_data(custom, coolness);  /* gets the csv data from `custom\coolness.csv` */
			%get_latest_data(coolness, latest_coolness)  /* make sure to use the most recent data */
			
			/* Add the data to the other related data */
			proc sql;
				create table glob_pos_data as
				select d.*, c.year as coolness_year, c.coolness as coolness
				from glob_pos_data d
				inner join latest_coolness c
				on d.fips = c.fips
				;
			quit;
			```


		b. Under "Finalize Data" generate ranks for the "Coolness" data in `proc rank`

			under `var`, add a line:
			`coolness /* this is the name of the variable that we added to the data*/`

			under `ranks`, add a line:
			`rank_coolness /* this is the rank name. it must contain the word "rank" to receive a grade */`
			

			
	3. In `macros\create_detailed_summary`, make sure that the new data gets picked up by the outputs

		a. in the `05_Global_Position` section, add a line:
		
			`%_append_category(values_05_global_position, "Global Position", "Coolness Factor", 507, coolness_year, coolness, rank_coolness)`

			(Read the macros at the bottom of `create_detailed_summary.sas` to understand what each variable does.)


	4. Perform a test-run of the code to verify that the new data is flowing through.
		(You'll need to set the current year and previous year to be equal for the test run, or the section that compares to previous years will crash.)
