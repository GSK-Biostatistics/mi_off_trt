/*******************************************************************************
|
| Program Name:    mmrm.sas
| Program Purpose: Fits MMRM models to the simulated data.
| SAS Version:     9.4
| Created By:      Thomas Drury
| Date:            20-04-18 
|
|-------------------------------------------------------------------------------
| Notes: 
|
|
*******************************************************************************/;


%macro mmrm(part=);

%include "/hpawrk/tad66240/repositories/sim_tools/sim_tools.sas";

%let part = %sysfunc(putn(&part.,z2.));
%let sess = %sysfunc(putn(&ms_n.,z2.));

options nofmterr cpucount = 3;

libname data "/hpawrk/tad66240/repositories/pub_mi_models/final/main/data";
libname results "/hpawrk/tad66240/repositories/pub_mi_models/final/main/results"; 


**********************************************************************************;
***  FIT MMRM                                                                  ***;
**********************************************************************************;

%start_time(startid=MMRM);
%ods_off(notesyn=N);

data simulations_mmrm;
  set data.simstudy1_part&part._sess&sess.;
  array yvals[3] y1-y3;
  do i = 1 to dim(yvals);
    z    = yvals[i] - y0;
    time = i;
    output;
  end;
run;

proc mixed data = simulations_mmrm;
  by scenario disctype discrate withrate withtype sim;
  class trtgroup time;
  model z = trtgroup*time y0*time / noint;
  repeated time / subject=subjid type=un;
  lsmeans trtgroup*time / diff=all cl;
  ods output lsmeans = lsm_mmrm;
  ods output diffs   = dif_mmrm;  
run;

%ods_on;
%stop_time(startid=MMRM);



**********************************************************************************;
*** STACK ALL RESULTS AND PUT IN RESULTS LIBRARY                               ***;
**********************************************************************************;

data results.lsm_mmrm_part&part._sess&sess.;
  set lsm_mmrm;
  by scenario disctype discrate withrate withtype sim;
  modelcd = 2;
  model   = "MMRM";
  if time = 3 then output;  *** KEEP ONLY FINAL TIMEPOINT LSM ***;
run;
      
data results.dif_mmrm_part&part._sess&sess.;
  set dif_mmrm;
  by scenario disctype discrate withrate withtype sim; 
  modelcd = 2;
  model   = "MMRM";
  if time = 3 and _time = 3 then do;
    trtgroup  = 2;
    _trtgroup = 1;
    estimate = -estimate;                          *** CHANGE ESTIMATE TO ACTIVE VS CONTROL ***;
    lower = estimate - probit(1-0.05/2) * stderr;  *** CREATE LOWER CI ***;       
    upper = estimate + probit(1-0.05/2) * stderr;  *** CREATE UPPER CI ***;
    output;
  end;
run;


**********************************************************************************;
*** DELETE ALL SIMDATA VERSIONS OF MIA AND FIT DATA                            ***;
**********************************************************************************;

proc datasets lib = work nolist;
  delete simulations_mmrm lsm_mmrm dif_mmrm;
quit;
run;

%mend mmrm;


















