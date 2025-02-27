/*******************************************************************************
|
| Program Name:    full.sas
| Program Purpose: Fits ANCOVA model to the full simulated data values.
| SAS Version:  9.4
| Created By:   Thomas Drury
| Date:         20-04-18 
|
|-------------------------------------------------------------------------------
| Notes: 
|
|
*******************************************************************************/;

%macro full(part=);

%include "/hpawrk/tad66240/repositories/sim_tools/sim_tools.sas";

%let part = %sysfunc(putn(&part.,z2.));
%let sess = %sysfunc(putn(&ms_n.,z2.));

options nofmterr cpucount = 3;

libname data "/hpawrk/tad66240/repositories/pub_mi_models/final/main/data";
libname results "/hpawrk/tad66240/repositories/pub_mi_models/final/main/results"; 


**********************************************************************************;
*** TRUE ANOVA                                                                 ***;
**********************************************************************************;

%start_time(startid=FULL);
%ods_off(notesyn=N);

*** CREATE CHANGE FROM BASELINE ***;
data simulations_full;
  set data.simstudy1_part&part._sess&sess.;
  z_true3 = y_true3 - y_true0;
run;

*** FIT ANCOVA MODEL ***;
proc mixed data = simulations_full;
  by scenario disctype discrate withrate withtype sim;
  class trtgroup;
  model z_true3 = trtgroup y_true0 / noint;
  lsmeans trtgroup / diff=control("1") cl;
  ods output lsmeans = lsm_full;
  ods output diffs   = dif_full; 
run;

%ods_on;
%stop_time(startid=FULL);


**********************************************************************************;
*** STACK ALL RESULTS AND PUT IN RESULTS LIBRARY                               ***;
**********************************************************************************;

data results.lsm_full_part&part._sess&sess.;
  set lsm_full;
  by scenario disctype discrate withrate withtype sim;
  modelcd = 1;
  model   = "FULL";
run;
      
data results.dif_full_part&part._sess&sess.;
  set dif_full;
  by scenario disctype discrate withrate withtype sim;
  modelcd = 1;
  model   = "FULL";
run;


**********************************************************************************;
*** DELETE ALL SIMDATA VERSIONS OF MIA AND FIT DATA                            ***;
**********************************************************************************;

proc datasets lib = work nolist;
  delete simulations_full lsm_full dif_full;
quit;
run;

%mend full;


















