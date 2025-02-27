/*******************************************************************************
|
| Program Name:    mi_r.sas
| Program Purpose: Uses R models for multiple imputation for data values.
| SAS Version:     9.4
| Created By:      Thomas Drury
| Date:            20-04-18 
|
|-------------------------------------------------------------------------------
| Notes: 
|
|
*******************************************************************************/;


%macro mi_r(part=, impseed=, nimps=);

%let rseed0 = %sysevalf(&impseed. + 000 + &ms_n.);
%let rseed1 = %sysevalf(&impseed. + 100 + &ms_n.);
%let rseed2 = %sysevalf(&impseed. + 200 + &ms_n.);
%let rseed3 = %sysevalf(&impseed. + 300 + &ms_n.);

%let part = %sysfunc(putn(&part.,z2.));
%let sess = %sysfunc(putn(&ms_n.,z2.));

%inc "/hpawrk/tad66240/repositories/sim_tools/sim_tools.sas";
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/mistep/mistep12.sas";
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/mistep/mianalyze04.sas";

options cpucount = 2 nofmterr;

libname data "/hpawrk/tad66240/repositories/pub_mi_models/final/main/data";
libname results "/hpawrk/tad66240/repositories/pub_mi_models/final/main/results"; 

data simulations;
  set data.simstudy1_part&part._sess&sess.;
run;

********************************************************************************;
*** FIT MODEL R1                                                             ***;
********************************************************************************;

%start_time(startid=R1_MISTEP);
%ods_off(notesyn=N);

*** IMPUTE USING R1 VIA MI STEP ***;
%mistep(data=simulations, out=imputations0, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y0, class=sim, model=%str(sim), suffix=0, nimpute=&nimps., seed=%sysevalf(&rseed0.));

%mistep(data=imputations0, out=imputations1, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y1, class=d1, model=%str(d1 residual0), nimpute=1, seed=%sysevalf(&rseed1.));

%mistep(data=imputations1, out=imputations2, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y2, class=d2, model=%str(d2 residual0 residual1), nimpute=1, seed=%sysevalf(&rseed2.));

%mistep(data=imputations2, out=imputations3, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y3, class=d3, model=%str(d3 residual0 residual1 residual2), nimpute=1, seed=%sysevalf(&rseed3.));


*** CREATE CHANGE FROM BASELINE ***;
data imputations3;
  set imputations3;
  z3 = imputed3 - y0;
run;

proc datasets lib = work nolist;
  delete r1_mistep_lsm;
run;

*** COMBINE RESULTS AND FIT ANCOVA ***;
%mianalyze(data=imputations3, results=lsm_mia_r1_mistep
          ,by=%str(scenario disctype discrate withrate withtype sim)
          ,response=z3, class=trtgroup, model=%str(trtgroup y0), lsmeans=trtgroup, label=%str(R1 via MIStep Macro));


*** TIDY UP WORK AREA ***;
proc datasets lib = work nolist;
  delete imputations0-imputations3;
run;

%ods_on;
%stop_time(startid=R1_MISTEP);
  
  

********************************************************************************;
*** FIT MODEL R2 EQUIVILENT TO OUR A2 MODEL                                  ***;
********************************************************************************;

%ods_off(notesyn=N);
%start_time(startid=R2_MISTEP);


*** IMPUTE USING R2 VIA MI STEP ***;
%mistep(data=simulations, out=imputations0, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y0, class=sim, model=%str(sim), suffix=0, nimpute=&nimps., seed=%sysevalf(&rseed0.));

%mistep(data=imputations0, out=imputations1, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y1, class=d1, model=%str(d1 residual0), nimpute=1, seed=%sysevalf(&rseed1.));

%mistep(data=imputations1, out=imputations2, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y2, class=%str(d1 d2), model=%str(d1 d2 residual0 residual1), nimpute=1, seed=%sysevalf(&rseed2.));

%mistep(data=imputations2, out=imputations3, by=%str(scenario disctype discrate withrate withtype sim trtgroup)
       ,response=y3, class=%str(d1 d2 d3), model=%str(d1 d2 d3 residual0 residual1 residual2), nimpute=1, seed=%sysevalf(&rseed3.));


*** CREATE CHANGE FROM BASELINE ***;
data imputations3;
  set imputations3;
  z3 = imputed3 - y0;
run;

proc datasets lib = work nolist;
  delete r1_mistep_lsm;
run;

*** COMBINE RESULTS AND FIT ANCOVA ***;
%mianalyze(data=imputations3, results=lsm_mia_r2_mistep
          ,by=%str(scenario disctype discrate withrate withtype sim)
          ,response=z3, class=trtgroup, model=%str(trtgroup y0), lsmeans=trtgroup, label=%str(R2 via MIStep Macro));


*** TIDY UP WORK AREA ***;
proc datasets lib = work nolist;
  delete imputations0-imputations3;
run;


%ods_on;
%stop_time(startid=R2_MISTEP);
    

**********************************************************************************;
*** STACK ALL RESULTS AND PUT IN RESULTS LIBRARY                               ***;
**********************************************************************************;

 
*** PUT MIA LSM DATA INTO RESULTS AREA ***;
data lsm_mia_r;
  set lsm_mia_r1_mistep (in = in1 where = (_trtgroup = .))
      lsm_mia_r2_mistep (in = in2 where = (_trtgroup = .));
  by scenario disctype discrate withrate withtype sim trtgroup;
       
  if in1       then modelcd = 9;
  else if in2  then modelcd = 10;
       
  select(modelcd);
    when (09) model = "R1";
    when (10) model = "R2";
    otherwise;
  end;
         
  *** CREATE CIS ***;       
  lower = estimate - probit(1-0.05/2) * se;
  upper = estimate + probit(1-0.05/2) * se;
         
run;     
   
proc sort data = lsm_mia_r
          out  = results.lsm_mia_r_part&part._sess&sess.;
  by scenario disctype discrate withrate withtype trtgroup sim;
run;
   
   
*** PUT MIA DIF DATA INTO RESULTS AREA ***;     
data dif_mia_r;
  set lsm_mia_r1_mistep (in = in1 where = (_trtgroup ne .))
      lsm_mia_r2_mistep (in = in2 where = (_trtgroup ne .));
  by scenario disctype discrate withrate withtype sim trtgroup _trtgroup;
       
  if in1       then modelcd = 9;
  else if in2  then modelcd = 10;
       
  select(modelcd);
    when (09)  model = "R1";
    when (10)  model = "R2";
    otherwise;
  end;
     
  *** CHANGE DIRECTION OF THE ESTIMATE AS IT DOES TRT=1 V TRT=2 RATHER THAN 2V1 ***;   
  estimate = -estimate;   
     
  *** CREATE CIS ***;       
  lower = estimate - probit(1-0.05/2) * se;
  upper = estimate + probit(1-0.05/2) * se;
      
run;       
 
proc sort data = dif_mia_r
          out  = results.dif_mia_r_part&part._sess&sess.;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
run;
   
 
**********************************************************************************;
*** DELETE ALL PARALLEL VERSIONS OF MIA DATA                                   ***;
**********************************************************************************;

proc datasets lib = work nolist;
  delete simulations
         lsm_mia_r1_mistep 
         lsm_mia_r2_mistep
         lsm_mia_r
         dif_mia_r;
quit;
run;  
  
%mend mi_r;  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  