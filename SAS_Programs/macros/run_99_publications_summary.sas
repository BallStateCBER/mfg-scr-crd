/*
#############################################################################
Objective:
	Takes the outputs from this scorecard and the previous scorecard,
	and combines them into a format that's easy for Publications to use.

Author:
	Brandon Patterson

Notes:
	
#############################################################################
*/

%macro run_99_publications_summary();

	/* Get the Final grade details for each Category */
	data pub_data;
		retain state category old_grade change new_grade;
		set out.all_details;
		/* set the format of the new column */
		format change $6.;

		/* only use final results */
		if subcategory ^= "Final Results" then delete;
		
		/* determine whether grades have moved up/down/same */
		if (new_grade ^= old_grade) then do;
			if new_rank < old_rank then change = "!up!";
			else change = "!down!";
		end;
		else change = "!same!";

		/* only keep needed fields */
		keep state category old_grade change new_grade;
	run;

	/* Ugly SQL code, but gets the job done (couldn't figure out how to use proc transpose effectively) */
	proc sql;
		create table pub_data_wide as
		select mfg.state
			,mfg.old_grade as mfg_old, mfg.change as mfg_change, mfg.new_grade as mfg_new
			,log.old_grade as log_old, log.change as log_change, log.new_grade as log_new
			,hc.old_grade as hum_cap_old, hc.change as hum_cap_change, hc.new_grade as hum_cap_new
			,ben.old_grade as ben_cost_old, ben.change as ben_cost_change, ben.new_grade as ben_cost_new
			,tax.old_grade as tax_old, tax.change as tax_change, tax.new_grade as tax_new
			,flg.old_grade as fisc_gap_old, flg.change as fisc_gap_change, flg.new_grade as fisc_gap_new
			,glb.old_grade as glob_pos_old, glb.change as glob_pos_change, glb.new_grade as glob_pos_new
			,div.old_grade as diversity_old, div.change as diversity_change, div.new_grade as diversity_new
			,prd.old_grade as prod_innov_old, prd.change as prod_innov_change, prd.new_grade as prod_innov_new
		from (select * from pub_data where category = "Manufacturing") mfg
		join (select * from pub_data where category = "Logistics") log
			on mfg.state = log.state
		join (select * from pub_data where category = "Human Capital") hc
			on mfg.state = hc.state
		join (select * from pub_data where category = "Benefits Costs") ben
			on mfg.state = ben.state
		join (select * from pub_data where category = "Tax Climate") tax
			on mfg.state = tax.state
		join (select * from pub_data where category = "Expected Fiscal Liability Gap") flg
			on mfg.state = flg.state
		join (select * from pub_data where category = "Global Position") glb
			on mfg.state = glb.state
		join (select * from pub_data where category = "Diversification") div
			on mfg.state = div.state
		join (select * from pub_data where category = "Productivity and Innovation") prd
			on mfg.state = prd.state
		;
	quit;

	/* Add human-readable labels to the data */
	data pub_data_wide;
		set pub_data_wide;
		label
			state = "State"
			mfg_old = "Manufacturing &prev_year."
			mfg_change = "Manufacturing Change"
			mfg_new = "Manufacturing &curr_year."
			log_old = "Logistics &prev_year."
			log_change = "Logistics Change"
			log_new = "Logistics &curr_year."
			hum_cap_old = "Human Capital &prev_year."
			hum_cap_change = "Human Capital Change"
			hum_cap_new = "Human Capital &curr_year."
			ben_cost_old = "Benefit Costs &prev_year."
			ben_cost_change = "Benefit Costs Change"
			ben_cost_new = "Benefit Costs &curr_year."
			tax_old = "Tax Climate &prev_year."
			tax_change = "Tax Climate Change"
			tax_new = "Tax Climate &curr_year."
			fisc_gap_old = "Expected Fiscal Liability ap &prev_year."
			fisc_gap_change = "Expected Fiscal Liability ap Change"
			fisc_gap_new = "Expected Fiscal Liability ap &curr_year."
			glob_pos_old = "Global Reach &prev_year."
			glob_pos_change = "Global Reach Change"
			glob_pos_new = "Global Reach &curr_year."
			diversity_old = "Sector Diversification &prev_year."
			diversity_change = "Sector Diversification Change"
			diversity_new = "Sector Diversification &curr_year."
			prod_innov_old = "Productivity and Innovation &prev_year."
			prod_innov_change = "Productivity and Innovation Change"
			prod_innov_new = "Productivity and Innovation &curr_year."
		;
	run;


	/* Output the data for the Publications Team to use */
	proc export
		data=pub_data_wide
		outfile="&rootpath.&curr_fldr.\Summaries\Aggregate\_for_publications_&curr_year..csv"
		label
		dbms=csv
		replace
		;
	run;


	%clr_lib();

%mend run_99_publications_summary;
