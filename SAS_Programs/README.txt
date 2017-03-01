
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


