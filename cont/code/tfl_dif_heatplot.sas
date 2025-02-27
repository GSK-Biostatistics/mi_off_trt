/*******************************************************************************
|
| Program Name   : tfl_dif_heatplot.sas
| Program Purpose: Plots of the Bias in Difference in LSM 
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
 
libname results "/hpawrk/tad66240/repositories/pub_mi_models/final/main/results";
libname summary "/hpawrk/tad66240/repositories/pub_mi_models/final/main/summary";
filename outdir "/hpawrk/tad66240/repositories/pub_mi_models/final/main/output/";

*** PLOT MACRO CODE ***;
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/tfl_heatplot1.sas"; 

 
********************************************************************************;
*** GET DATA                                                                 ***;
********************************************************************************;

proc sort data = summary.dif_bias
          out  = dif_bias;
  by scenario disctype discrate withrate withtype modelcd;
run;

proc sort data = summary.dif_ci_halfwidth
          out  = dif_ci_halfwidth;
  by scenario disctype discrate withrate withtype modelcd;
run;

proc sort data = summary.dif_ci_coverage
          out  = dif_ci_coverage;
  by scenario disctype discrate withrate withtype modelcd;
run;



********************************************************************************;
*** CREATE TABLE FRAME                                                       ***;
********************************************************************************;

data dif_table;
  
  length var_lbl1 $25 var_lbl2 $5 var_lbl3 $12;
  
  all = 1;
         
         
  do scenario = 1, 2;
  do disctype = 1, 2;
  do case = 1 to 24;
     
   if case = 1 then var_lbl1  = "10% Control: 10% Active";
   else if case = 7 then var_lbl1  = "10% Control: 20% Active";
   else if case = 13 then var_lbl1 = "20% Control: 20% Active";
   else if case = 19 then var_lbl1 = "50% Control: 50% Active";
   else var_lbl1 = " ";
   
   if case in (1, 7, 13, 19) then var_lbl2 = "50%";
   else if case in (4, 10, 16, 22) then var_lbl2 = "70%";
   else var_lbl2 = " "; 
   
   if case      in (1, 4, 7, 10, 13, 16, 19, 22) then var_lbl3 = "More Early";
   else if case in (2, 5, 8, 11, 14, 17, 20, 23) then var_lbl3 = "Balanced"; 
   else if case in (3, 6, 9, 12, 15, 18, 21, 24) then var_lbl3 = "More Late"; 
   else var_lbl3 = " ";

   output;
   
  end;
  end;
  end;

run;
   
   
********************************************************************************;
*** REMERGE FULL HALFWIDTH AND COVERAGE DATA ON                              ***;
********************************************************************************;
    
data dif_relative_halfwidth;
  merge dif_ci_halfwidth
        dif_ci_halfwidth (where = (modelcd=1) rename=(ci_halfwidth_mean = _ci_halfwidth_mean));
  by scenario disctype discrate withrate withtype;

  ci_relative_halfwidth_mean = 100*((ci_halfwidth_mean - _ci_halfwidth_mean)/_ci_halfwidth_mean); 
  keep scenario disctype discrate withrate withtype modelcd model ci_halfwidth_mean _ci_halfwidth_mean ci_relative_halfwidth_mean;  

run;

    
data dif_relative_coverage;
  merge dif_ci_coverage
        dif_ci_coverage (where = (modelcd=1) rename=(ci_coverage_mean = _ci_coverage_mean));
  by scenario disctype discrate withrate withtype;

  ci_relative_coverage_mean = 100*((ci_coverage_mean - _ci_coverage_mean)/_ci_coverage_mean); 
  keep scenario disctype discrate withrate withtype modelcd model ci_coverage_mean _ci_coverage_mean ci_relative_coverage_mean;  

run;

 
data dif_results;
  merge dif_bias                (keep = scenario disctype discrate withrate withtype modelcd model bias_estimate_mean)
        dif_relative_halfwidth  (keep = scenario disctype discrate withrate withtype modelcd model ci_relative_halfwidth_mean)
        dif_relative_coverage   (keep = scenario disctype discrate withrate withtype modelcd model ci_relative_coverage_mean);
        
  by scenario disctype discrate withrate withtype modelcd;
  
  if first.disctype then case = 0;
  if first.withtype then case + 1;

  select(model);
    when ("FULL")  modelnum = 1;
    when ("MMRM")  modelnum = 2;
    when ("A0")    modelnum = 3;
    when ("A1")    modelnum = 4;
    when ("R1")    modelnum = 5;
    when ("A3")    modelnum = 6;
    when ("A2")    modelnum = 7;
    when ("R2")    modelnum = 8;
    when ("A4")    modelnum = 9;
    otherwise;
  end;


  if model = "A4" and scenario in (1, 2) and discrate in (1, 2) and withrate = 2 and withtype = 1 then delete;
  
  bias1 = round(bias_estimate_mean, 1);
  hw1 = round(ci_relative_halfwidth_mean, 1);
  cic1 = round(ci_relative_coverage_mean, 1);

  if 1 <= modelnum <= 9 then output;

run;



data heatplot;
  set dif_results
      dif_table;
      
  var_lbl1 = strip(var_lbl1);
  var_lbl2 = strip(var_lbl2);
  var_lbl3 = strip(var_lbl3);
      
run;

goptions gsfmode=replace;

ods listing gpath=outdir;
ods graphics / width = 12in height=6.5in imagename="dif_heatplot1" imagefmt=svg; 
%heatplot1(indata=heatplot, inwhere=%str(where scenario = 1 and disctype = 1), t1=Scenario: Return to Baseline - DAR);
ods graphics off;  
ods listing close;

ods listing gpath=outdir;
ods graphics / width = 12in height=6.5in imagename="dif_heatplot2" imagefmt=svg; 
%heatplot1(indata=heatplot, inwhere=%str(where scenario = 2 and disctype = 1), t1=Scenario: Same as Active - DAR);
ods graphics off;  
ods listing close;

ods listing gpath=outdir;
ods graphics / width = 12in height=6.5in imagename="dif_heatplot3" imagefmt=svg; 
%heatplot1(indata=heatplot, inwhere=%str(where scenario = 1 and disctype = 2), t1=Scenario: Return to Baseline - DNAR);
ods graphics off;  
ods listing close;

ods listing gpath=outdir;
ods graphics / width = 12in height=6.5in imagename="dif_heatplot4" imagefmt=svg; 
%heatplot1(indata=heatplot, inwhere=%str(where scenario = 2 and disctype = 2), t1=Scenario: Same as Active - DNAR);
ods graphics off;  
ods listing close;

