/*******************************************************************************
|
| Program Name:    mi_a.sas
| Program Purpose: Uses A models for multiple imputation for data values.
| SAS Version:     9.4
| Created By:      Thomas Drury
| Date:            20-04-18 
|
|-------------------------------------------------------------------------------
| Notes: 
|
|
*******************************************************************************/;

%macro mi_a(part=, impseed=, nimps=);

%let aseed1 = %sysevalf(&impseed. + 100 + &ms_n.);
%let aseed2 = %sysevalf(&impseed. + 200 + &ms_n.);
%let aseed3 = %sysevalf(&impseed. + 300 + &ms_n.);

%let part = %sysfunc(putn(&part.,z2.));
%let sess = %sysfunc(putn(&ms_n.,z2.));

%inc "/hpawrk/tad66240/repositories/sim_tools/sim_tools.sas";

options cpucount = 3 nofmterr;

libname data "/hpawrk/tad66240/repositories/pub_mi_models/final/main/data";
libname results "/hpawrk/tad66240/repositories/pub_mi_models/final/main/results"; 

proc sql noprint;
  select distinct nsubs into :nsubs
  from data.simstudy1_part&part._sess&sess.;
quit;


**********************************************************************************;
*** FIT A0 MODEL (CICS)                                                        ***;
**********************************************************************************;

%start_time(startid=A0);
%ods_off(notesyn=N);

proc mi data    = data.simstudy1_part&part._sess&sess.
        out     = imputations0 (rename= (_imputation_ = imputation)) 
        seed    = &aseed1. 
        nimpute = &nimps.;    
  by scenario disctype discrate withrate withtype sim trtgroup;   
  var y0-y3 ;
  monotone reg(y1=y0);
  monotone reg(y2=y0 y1);
  monotone reg(y3=y0 y1 y2);
run;

proc summary data = imputations0 nway;
  class scenario disctype discrate withrate withtype sim trtgroup;
  var imputation;
  output out = work.fit_a0 
         n   = imputed;
run;

proc sort data = imputations0;
  by scenario disctype discrate withrate withtype sim imputation;
run;

data imputations0;
  set imputations0;
  z3 = y3 - y0;
run;

proc mixed data = imputations0;
  by scenario disctype discrate withrate withtype sim imputation;
  class trtgroup;
  model z3 = trtgroup y0 / noint;
  lsmeans trtgroup / diff=control("1") cl; 
  ods output lsmeans = lsm_a0;
  ods output diffs   = dif_a0; 
run;

proc sort data = lsm_a0;
  by scenario disctype discrate withrate withtype trtgroup sim;
run;

proc mianalyze data = lsm_a0;
  by scenario disctype discrate withrate withtype trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = lsm_mia_a0;
run;

proc sort data = dif_a0;  
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
run;

proc mianalyze data = dif_a0;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = dif_mia_a0;
run;

proc datasets lib = work nolist;
  delete imputations0 lsm_a0 dif_a0;
quit;

%ods_on;
%stop_time(startid=A0);


**********************************************************************************;
*** FIT MODEL A1 (OICS)                                                        ***;
**********************************************************************************;

%start_time(startid=A1);
%ods_off(notesyn=N);

proc mi data    = data.simstudy1_part&part._sess&sess. 
        out     = imputations1 (rename= (_imputation_ = imputation)) 
        seed    = &aseed1. 
        nimpute = &nimps.;    
  by scenario disctype discrate withrate withtype sim trtgroup;  
  class d1 d2 d3;
  var d1 d2 d3 y0-y3 ;
  monotone reg( y1 = d1 y0 );
  monotone reg( y2 = d2 y0 y1);
  monotone reg( y3 = d3 y0 y1 y2);
run;

proc summary data = imputations1 nway;
  class scenario disctype discrate withrate withtype sim trtgroup;  
  var imputation;
  output out = fit_a1 
         n   = imputed;
run;

proc sort data = imputations1;
  by scenario disctype discrate withrate withtype sim imputation;  
run;

data imputations1;
  set imputations1;
  z3 = y3 - y0;
run;

proc mixed data = imputations1;
  by scenario disctype discrate withrate withtype sim imputation; 
  class trtgroup;
  model z3 = trtgroup y0 / noint;
  lsmeans trtgroup / diff=control("1") cl; 
  ods output lsmeans = lsm_a1;
  ods output diffs   = dif_a1;   
run;

proc sort data = lsm_a1;
  by scenario disctype discrate withrate withtype trtgroup sim;
run;

proc mianalyze data = lsm_a1;
  by scenario disctype discrate withrate withtype trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = lsm_mia_a1;
run;

proc sort data = dif_a1;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
run;

proc mianalyze data = dif_a1;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = dif_mia_a1;
run;

proc datasets lib = work nolist;
  delete imputations1 lsm_a1 dif_a1;
quit;

%ods_on;
%stop_time(startid=A1);


**********************************************************************************;
*** FIT MODEL A2 (PICS)                                                        ***;
**********************************************************************************;

%start_time(startid=A2);
%ods_off(notesyn=N);

proc mi data    = data.simstudy1_part&part._sess&sess. 
        out     = imputations2 (rename= (_imputation_ = imputation)) 
        seed    = &aseed1. 
        nimpute = &nimps.;    
  by scenario disctype discrate withrate withtype sim trtgroup;
  class d1 d2 d3;
  var d1 d2 d3 y0-y3 ;
  monotone reg( y1 = d1 y0 );
  monotone reg( y2 = d1 d2 y0 y1 );
  monotone reg( y3 = d1 d2 d3 y0 y1 y2 );
run;

proc summary data = imputations2 nway;
  class scenario disctype discrate withrate withtype sim trtgroup;
  var imputation;
  output out = fit_a2 
         n   = imputed;
run;

proc sort data = imputations2;
  by scenario disctype discrate withrate withtype sim imputation;
run;

data imputations2;
  set imputations2;
  z3 = y3 - y0;
run;

proc mixed data = imputations2;
  by scenario disctype discrate withrate withtype sim imputation;
  class trtgroup;
  model z3 = trtgroup y0 / noint;
  lsmeans trtgroup / diff=control("1") cl; 
  ods output lsmeans = lsm_a2;
  ods output diffs   = dif_a2;   
run;

proc sort data = lsm_a2;
  by scenario disctype discrate withrate withtype trtgroup sim;
run;

proc mianalyze data = lsm_a2;
  by scenario disctype discrate withrate withtype trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = lsm_mia_a2;
run;

proc sort data = dif_a2;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
run;

proc mianalyze data = dif_a2;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = dif_mia_a2;
run;

proc datasets lib = work nolist;
  delete imputations2 lsm_a2 dif_a2;
quit;

%ods_on;
%stop_time(startid=A2);


**********************************************************************************;
*** FIT MODEL A3 (OIOS)                                                        ***;
**********************************************************************************;

%start_time(startid=A3);
%ods_off(notesyn=N);

proc mi data    = data.simstudy1_part&part._sess&sess.      
        out     = imputations3 (rename= (_imputation_ = imputation)) 
        seed    = &aseed1. 
        nimpute = &nimps.;    
  by scenario disctype discrate withrate withtype sim trtgroup;
  class d1 d2 d3;
  var d1 d2 d3 y0-y3;
  monotone reg( y1 = d1 y0 ); 
  monotone reg( y2 = d2 y0 y1 d2*y1 );
  monotone reg( y3 = d3 y0 y1 y2 d3*y1 d3*y2 );
run;

proc summary data = imputations3 nway;
  class scenario disctype discrate withrate withtype sim trtgroup;
  var imputation;
  output out = fit_a3 
         n   = imputed;
run;

proc sort data = imputations3;
  by scenario disctype discrate withrate withtype sim imputation;
run;

data imputations3;
  set imputations3;
  z3 = y3 - y0;
run;

proc mixed data = imputations3;
  by scenario disctype discrate withrate withtype sim imputation;
  class trtgroup;
  model z3 = trtgroup y0 / noint;
  lsmeans trtgroup / diff=control("1") cl; 
  ods output lsmeans = lsm_a3;
  ods output diffs   = dif_a3;  
run;

proc sort data = lsm_a3;
  by scenario disctype discrate withrate withtype trtgroup sim;
run;

proc mianalyze data = lsm_a3;
  by scenario disctype discrate withrate withtype trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = lsm_mia_a3;
run;

proc sort data = dif_a3;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
run;

proc mianalyze data = dif_a3;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = dif_mia_a3;
run;

proc datasets lib = work nolist;
  delete imputations3: lsm_a3 dif_a3;
quit;

%ods_on;
%stop_time(startid=A3);


**********************************************************************************;
*** FIT MODEL A4 (PIOS)                                                        ***;
**********************************************************************************;

%start_time(startid=A4);
%ods_off(notesyn=N);

proc mi data    = data.simstudy1_part&part._sess&sess.      
        out     = imputations4 (rename= (_imputation_ = imputation)) 
        seed    = &aseed1. 
        nimpute = &nimps.;    
  by scenario disctype discrate withrate withtype sim trtgroup;
  class d1 d2 d3;
  var d1 d2 d3 y0-y3;
  monotone reg(y1 = d1 y0); 
  monotone reg(y2 = d1 d2 y0 y1 d1*y1 );
  monotone reg(y3 = d1 d2 d3 y0 y1 y2 d1*y1 d2*y2 );
run;

proc summary data = imputations4 nway;
  class scenario disctype discrate withrate withtype sim trtgroup;
  var imputation;
  output out = fit_a4 
         n   = imputed;
run;

proc sort data = imputations4;
  by scenario disctype discrate withrate withtype sim imputation;
run;

data imputations4;
  set imputations4;
  z3 = y3 - y0;
run;

proc mixed data = imputations4;
  by scenario disctype discrate withrate withtype sim imputation;
  class trtgroup;
  model z3 = trtgroup y0 / noint;
  lsmeans trtgroup / diff=control("1") cl; 
  ods output lsmeans = lsm_a4;
  ods output diffs   = dif_a4; 
run;

proc sort data = lsm_a4;
  by scenario disctype discrate withrate withtype trtgroup sim;
run;

proc mianalyze data = lsm_a4;
  by scenario disctype discrate withrate withtype trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = lsm_mia_a4;
run;

proc sort data = dif_a4;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
run;

proc mianalyze data = dif_a4;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = dif_mia_a4;
run;

proc datasets lib = work nolist;
  delete imputations4: lsm_a4 dif_a4;
quit;

%ods_on;
%stop_time(startid=A4);

**********************************************************************************;
*** FIT MODEL A5 (PIPS)                                                        ***;
**********************************************************************************;

%start_time(startid=A5);
%ods_off(notesyn=N);

data simulations5_com;
  set data.simstudy1_part&part._sess&sess.;
  by scenario disctype discrate withrate withtype sim trtgroup;
  where disctime = 3;
  do imputation = 1 to &nimps.;
    output;            *** DUPLICATE COMPLETERS ***;
  end;
run;
     
data simulations5_imp;
  set data.simstudy1_part&part._sess&sess.;
  by scenario disctype discrate withrate withtype sim trtgroup;
  where disctime lt 3; 
run;

proc sort data = simulations5_imp;
  by scenario disctype discrate withrate withtype sim trtgroup disctime;
run;

proc mi data    = simulations5_imp 
        out     = imputations5
        seed    = &aseed1. 
        nimpute = &nimps.;    
  by scenario disctype discrate withrate withtype sim trtgroup disctime;
  var y0-y3;
  monotone reg( y1 = y0 );
  monotone reg( y2 = y0 y1 );
  monotone reg( y3 = y0 y1 y2 );
run;

data imputations5;
  set simulations5_com
      imputations5 (rename= (_imputation_ = imputation));
run;

proc summary data = imputations5 nway;
  class scenario disctype discrate withrate withtype sim trtgroup;
  var imputation;
  output out = fit_a5 
         n   = imputed;
run;

proc sort data = imputations5;
  by scenario disctype discrate withrate withtype sim imputation;
run;

data imputations5;
  set imputations5;
  z3 = y3 - y0;
run;

proc mixed data = imputations5;
  by scenario disctype discrate withrate withtype sim imputation;
  class trtgroup;
  model z3 = trtgroup y0 / noint;
  lsmeans trtgroup / diff=control("1") cl; 
  ods output lsmeans = lsm_a5;
  ods output diffs   = dif_a5; 
run;

proc sort data = lsm_a5;
  by scenario disctype discrate withrate withtype trtgroup sim;
run;

proc mianalyze data = lsm_a5;
  by scenario disctype discrate withrate withtype trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = lsm_mia_a5;
run;

proc sort data = dif_a5;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
run;

proc mianalyze data = dif_a5;
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;
  modeleffects estimate;
  stderr stderr;
  ods output parameterestimates = dif_mia_a5;
run;

proc datasets lib = work nolist;
  delete simulations5: imputations5: lsm_a5 dif_a5;
quit;


%ods_on;
%stop_time(startid=A5);


**********************************************************************************;
*** STACK ALL RESULTS AND PUT IN RESULTS LIBRARY                               ***;
**********************************************************************************;


*** PUT FIT DATA INTO RESULTS AREA ***;
data results.fit_a_part&part._sess&sess.;
  set fit_a0      (in = in0)
      fit_a1      (in = in1)
      fit_a2      (in = in2)
      fit_a3      (in = in3)
      fit_a4      (in = in4)
      fit_a5      (in = in5);
  by scenario disctype discrate withrate withtype sim trtgroup;
       
  total    = &nsubs.*&nimps.;
  percent  = 100*(imputed/total);
  complete = ifn(imputed = total, 1, 0);
        
  if in0      then modelcd = 3;
  else if in1 then modelcd = 4;
  else if in2 then modelcd = 5;
  else if in3 then modelcd = 6;
  else if in4 then modelcd = 7;
  else if in5 then modelcd = 8;
  
  select(modelcd);
    when (3)  model = "A0";
    when (4)  model = "A1";
    when (5)  model = "A2";
    when (6)  model = "A3";
    when (7)  model = "A4";
    when (8)  model = "A5";
    otherwise;
  end;
         
run;     


*** PUT MIA LSM DATA INTO RESULTS AREA ***;
data results.lsm_mia_a_part&part._sess&sess.;
  set lsm_mia_a0 (in = in0)
      lsm_mia_a1 (in = in1)
      lsm_mia_a2 (in = in2)
      lsm_mia_a3 (in = in3)
      lsm_mia_a4 (in = in4)    
      lsm_mia_a5 (in = in5);
  by scenario disctype discrate withrate withtype trtgroup sim;    
        
  if in0      then modelcd = 3;
  else if in1 then modelcd = 4;
  else if in2 then modelcd = 5;
  else if in3 then modelcd = 6;
  else if in4 then modelcd = 7;
  else if in5 then modelcd = 8;
  
  select(modelcd);
    when (3)  model = "A0";
    when (4)  model = "A1";
    when (5)  model = "A2";
    when (6)  model = "A3";
    when (7)  model = "A4";
    when (8)  model = "A5";
    otherwise;
  end;
         
run;     
   
   
*** PUT MIA DIF DATA INTO RESULTS AREA ***;     
data results.dif_mia_a_part&part._sess&sess.;
  set dif_mia_a0      (in = in0)
      dif_mia_a1      (in = in1)
      dif_mia_a2      (in = in2)
      dif_mia_a3      (in = in3)
      dif_mia_a4      (in = in4)
      dif_mia_a5      (in = in5);
  by scenario disctype discrate withrate withtype trtgroup _trtgroup sim;     
        
  if in0      then modelcd = 3;
  else if in1 then modelcd = 4;
  else if in2 then modelcd = 5;
  else if in3 then modelcd = 6;
  else if in4 then modelcd = 7;
  else if in5 then modelcd = 8;
  
  select(modelcd);
    when (3)  model = "A0";
    when (4)  model = "A1";
    when (5)  model = "A2";
    when (6)  model = "A3";
    when (7)  model = "A4";
    when (8)  model = "A5";
    otherwise;
  end;
         
run;     



**********************************************************************************;
*** DELETE ALL PARALLEL VERSIONS OF MIA AND FIT DATA                           ***;
**********************************************************************************;

proc datasets lib = work nolist;
  delete fit_a0-fit_a5 
         lsm_mia_a0-lsm_mia_a5 
         dif_mia_a0-dif_mia_a5 
         ;
quit;
run;

%mend mi_a;


















