/*******************************************************************************
|
| Program Name   : sum_dif.sas
| Program Purpose: Summarises the Difference in LSM.
| SAS Version    : 9.4
| Created By     : Thomas Drury
| Date           : 04-08-20 
|
|--------------------------------------------------------------------------------
|
*******************************************************************************/

*******************************************************************************;
***  SET UP                                                                 ***;
*******************************************************************************;

*** INCLUDE SIM TOOLS ***;
%include "/hpawrk/tad66240/repositories/sim_tools/sim_tools.sas";

libname results "/hpawrk/tad66240/repositories/pub_mi_models/final/main/results";
libname summary "/hpawrk/tad66240/repositories/pub_mi_models/final/main/summary";

%let npart = 20;
%let nsess = 25;


**********************************************************************************;
*** STACK FIT RESULTS TOGETHER                                                 ***;
**********************************************************************************;

%macro stack_data(lib=, prefix=, npart=, nsess=);

  data &prefix._all;
    set 
    
    %do ii = 1 %to &npart.;
    %do jj = 1 %to &nsess.;
      %let part = %sysfunc(putn(&ii.,z2.));
      %let sess = %sysfunc(putn(&jj.,z2.));
      &lib..&prefix._part&part._sess&sess. (in=p&part.s&sess.)
    %end;
    %end;
    ;

    %do ii = 1 %to &npart.;
    %do jj = 1 %to &nsess.;
      %let part = %sysfunc(putn(&ii.,z2.));
      %let sess = %sysfunc(putn(&jj.,z2.));
      if p&part.s&sess. then do; 
        part = &ii.; 
        sess = &jj.; 
      end;  
    %end;
    %end;

    ussid = strip(put(part,z3.))||"-"||strip(put(sess,z3.))||"-"||strip(put(sim,z3.));
  
  run;

%mend;

%stack_data(lib=results, prefix=dif_full,  npart=&npart., nsess=&nsess.);
%stack_data(lib=results, prefix=dif_mmrm,  npart=&npart., nsess=&nsess.);
%stack_data(lib=results, prefix=dif_mia_a, npart=&npart., nsess=&nsess.);
%stack_data(lib=results, prefix=dif_mia_r, npart=&npart., nsess=&nsess.);



**********************************************************************************;
*** SORT DATA                                                                  ***;
**********************************************************************************;

%macro sort_data(indata=, outdata=, bvars=);
  proc sort data = &indata. %if %length(&outdata.) ne 0 %then %do; out  = &outdata. %end;;
    by &bvars.;
  run;
%mend;


%sort_data(indata=summary.true_diffs, outdata=true_diffs, bvars=%str(scenario disctype discrate));


%sort_data(indata=dif_full_all,  bvars=%str(scenario disctype discrate withrate withtype ussid modelcd model));
%sort_data(indata=dif_mmrm_all,  bvars=%str(scenario disctype discrate withrate withtype ussid modelcd model));
%sort_data(indata=dif_mia_a_all, bvars=%str(scenario disctype discrate withrate withtype ussid modelcd model));
%sort_data(indata=dif_mia_r_all, bvars=%str(scenario disctype discrate withrate withtype ussid modelcd model));


**********************************************************************************;
*** STACK AND CALCULATE BIAS AND CI COVERAGE                                   ***;
**********************************************************************************;

*** STACK ALL MODELS ***;
data dif_models_all;
  set dif_full_all  (in = in1)
      dif_mmrm_all  (in = in2)
      dif_mia_a_all (in = in3 rename = (lclmean = lower uclmean = upper))
      dif_mia_r_all (in = in4 rename = (se = stderr));
  by scenario disctype discrate withrate withtype ussid modelcd model;
  
run;


proc sort data =  dif_models_all ;
  by scenario disctype discrate withrate withtype ussid modelcd model;
run;


*** MERGE ON TRUTH AND CALC BIAS AND CI COVERAGE ***;
data dif_all;
  merge dif_models_all (in = in1 )
        true_diffs     (in = in2 keep = scenario disctype discrate d_true:);
  by scenario disctype discrate;
  bias_estimate = (estimate - d_true3)*1000;  *** CONVERT TO MILLILITERS ***; 
  ci_halfwidth  = ((upper - lower) / 2)*1000; *** CONVERT TO MILLILITERS ***;
  ci_coverage   = (lower <= d_true3 <= upper);
run;


**********************************************************************************;
*** SUMMARIZE BIAS AND CI COVERAGE                                             ***;
**********************************************************************************;

*** SUMMARIZE THE BIAS ***;
ods select none;
proc means data = dif_all n mean stderr uclm lclm nway;
  class scenario disctype discrate withrate withtype modelcd model;
  var bias_estimate;
  ods output summary = summary.dif_bias;
run;
ods select all;  


*** SUMMARIZE THE CI HALFWIDTH ***;
ods select none;
proc means data = dif_all n mean stderr uclm lclm nway;
  class scenario disctype discrate withrate withtype modelcd model;
  var ci_halfwidth;
  ods output summary = summary.dif_ci_halfwidth;
run;
ods select all;  


*** SUMMARIZE THE CI COVERAGE ***;
ods select none;
proc means data = dif_all n mean stderr uclm lclm nway;
  class scenario disctype discrate withrate withtype modelcd model;
  var ci_coverage;
  ods output summary = summary.dif_ci_coverage;
run;
ods select all;  


**********************************************************************************;
*** CLEAN UP WORK AREA                                                         ***;
**********************************************************************************;

proc datasets lib = work nolist;
  delete true_diffs: dif_true: dif_mmrm: dif_mia: ;
quit;
run;





















