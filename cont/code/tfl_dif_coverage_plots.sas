/*******************************************************************************
|
| Program Name   : tfl_dif_coverage_plots.sas
| Program Purpose: Plots of the CI Coverage for Difference in LSM 
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
filename outhtm "/hpawrk/tad66240/repositories/pub_mi_models/final/main/output/";

%let htmlfile = dif_coverage_plots_1000.html;
 
*** PLOT MACRO CODE ***;
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/tfl_latticedotplot3.sas"; 
 
*** ***;  
proc format lib = work; 
                      
  value modelnum 0 = " " 
                 1 = "FULL"
                 2 = "MMRM"
                 3 = "CICS"
                 4 = "OICS"
                 5 = "OICS-R"
                 6 = "OIOS"                
                 7 = "PICS"
                 8 = "PICS-R"
                 9 = "PIOS"
                 10 = " ";                 

run; 
 
 
 
********************************************************************************;
*** GET DATA                                                                 ***;
********************************************************************************;

data dif_coverage;
  merge summary.dif_ci_coverage (where = (model="FULL") rename = (ci_coverage_mean = ci_coverage_full))
        summary.dif_ci_coverage;
  by scenario disctype discrate withrate withtype; 

  select(model);
    when ("FULL")           colourcd = 1;
    when ("MMRM", "A0")     colourcd = 2;
    when ("A1", "R1", "A3") colourcd = 3;
    when ("A2", "R2", "A4") colourcd = 4;
    otherwise;
  end;

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

  if 1 <= modelnum <=9 then output;

run;

data dif_coverage1
     dif_coverage2;
  set dif_coverage;
  
  ci_coverage_full = ci_coverage_full*100;
  
  ci_coverage_mean = ci_coverage_mean*100;
  ci_coverage_lclm = ci_coverage_lclm*100;
  ci_coverage_uclm = ci_coverage_uclm*100;

  if ci_coverage_mean le 84 then do;
     ci_truncated_label = strip(put(ci_coverage_mean,8.));
     ci_truncated_mean  = 84;
     ci_coverage_mean   = .;
     ci_coverage_lclm   = .;
     ci_coverage_uclm   = .;
  end;
  
  if withrate = 1 then output dif_coverage1;
  else if withrate = 2 then output dif_coverage2;
 
run;

 
********************************************************************************;
*** CREATE PLOTS                                                             ***;
********************************************************************************;

ods html path=outhtm gpath=outhtm file="&htmlfile.";
ods graphics on / width = 10in height=6in; 

*** RETURN TO BASELINE - DAR ***;

%latticedotplot3(indata=dif_coverage1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=1)             
                ,ttxt1 = %str(SI Figure 3.1)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(    ));
        
%latticedotplot3(indata=dif_coverage2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ytvar=%str(ci_truncated_mean), ytlabel=%str(ci_truncated_label) 
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=1)             
                ,ttxt1 = %str(SI Figure 3.2)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(    ));        


*** SAME AS ACTIVE - DAR ***;
        
%latticedotplot3(indata=dif_coverage1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=1)             
                ,ttxt1 = %str(SI Figure 3.3)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(    ));        
        
%latticedotplot3(indata=dif_coverage2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=1)             
                ,ttxt1 = %str(SI Figure 3.4)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(    ));        
                
        
*** RETURN TO BASELINE - DNAR ***;    
        
%latticedotplot3(indata=dif_coverage1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=2)             
                ,ttxt1 = %str(SI Figure 3.5)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(    ));
        
%latticedotplot3(indata=dif_coverage2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ytvar=%str(ci_truncated_mean), ytlabel=%str(ci_truncated_label) 
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=2)             
                ,ttxt1 = %str(SI Figure 3.6)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(    ));       


*** SAME AS ACTIVE - DNAR ***;
             
%latticedotplot3(indata=dif_coverage1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=2)             
                ,ttxt1 = %str(SI Figure 3.7)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(    ));
             
%latticedotplot3(indata=dif_coverage2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(ci_coverage_mean), ylower=%str(ci_coverage_lclm), yupper=%str(ci_coverage_uclm)
                ,ymin=84, ymax=100, yby=4, ylabel=%str(95% CI Coverage for Treatment Estimates), yref=%str(ci_coverage_full)
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=2)             
                ,ttxt1 = %str(SI Figure 3.8)
                ,ttxt2 = %str(95% CI Coverage for Treatment Estimates (Active vs. Control))      
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(    ));

ods graphics off;  
ods html close;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    