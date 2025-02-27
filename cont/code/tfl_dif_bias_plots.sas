/*******************************************************************************
|
| Program Name   : tfl_dif_bias.sas
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
filename outhtm "/hpawrk/tad66240/repositories/pub_mi_models/final/main/output/";

%let htmlfile = dif_bias_plots_1000.html;
 
*** PLOT MACRO CODE ***;
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/tfl_latticedotplot1.sas"; 
 
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

data dif_bias;
  set summary.dif_bias;

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

data dif_bias1;
  set dif_bias;
  where withrate = 1;
run;

data dif_bias2;
  set dif_bias;
  where withrate = 2;
run;

 
********************************************************************************;
*** CREATE PLOTS                                                             ***;
********************************************************************************;

ods html path=outhtm gpath=outhtm file="&htmlfile.";
ods graphics on / width = 10in height=6in; 

*** RETURN TO BASELINE - DAR ***;

%latticedotplot1(indata=dif_bias1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=1)             
                ,ttxt1 = %str(SI Figure 1.1)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(    ));

%latticedotplot1(indata=dif_bias2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=1)             
                ,ttxt1 = %str(SI Figure 1.2)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(Note: PIOS Bias (95%% CI) values: 10%% Control 10%% Active, More Early: -31.5 (-82.6, 19.6) and 10%% Control 20%% Active, More Early: -186.2 (-561.6, 189.2).) );


*** SAME AS ACTIVE - DAR ***;    

%latticedotplot1(indata=dif_bias1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=1)             
                ,ttxt1 = %str(SI Figure 1.3)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(     ));

%latticedotplot1(indata=dif_bias2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=1)             
                ,ttxt1 = %str(SI Figure 1.4)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(     ));

        
*** RETURN TO BASELINE - DNAR ***;

%latticedotplot1(indata=dif_bias1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=2)             
                ,ttxt1 = %str(SI Figure 1.5)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(    ));

%latticedotplot1(indata=dif_bias2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=1 and disctype=2)             
                ,ttxt1 = %str(SI Figure 1.6)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Return To Baseline)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(     ));


*** SAME AS ACTIVE - DNAR ***;  
              
%latticedotplot1(indata=dif_bias1, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=2)             
                ,ttxt1 = %str(SI Figure 1.7)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 50%%)
                ,ftxt1 = %str(    ));
             
%latticedotplot1(indata=dif_bias2, xvar=%str(modelnum), xmin=1, xmax=9, xby=1, xformat = %str(modelnum)
                ,yvar=%str(bias_estimate_mean), ylower=%str(bias_estimate_lclm), yupper=%str(bias_estimate_uclm)
                ,ymin=-20, ymax=60, yby=10, ylabel=%str(Bias for treatment effects (mL)), yref=0
                ,zvar = %str(colourcd), dsize=8
                ,inwhere = %str(where scenario=2 and disctype=2)             
                ,ttxt1 = %str(SI Figure 1.8)
                ,ttxt2 = %str(Bias for Treatment Effects - (Active vs. Control))                
                ,ttxt3 = %str(Disc. Scenario: Same As Active)
                ,ttxt4 = %str(Disc. Mechanism: DNAR)
                ,ttxt5 = %str(With. Rate: 70%%)
                ,ftxt1 = %str(Note: PIOS Bias (95%% CI) values: 10%% Control 10%% Active, More Early: 34.2 (-14.6, 83.0).) );

ods graphics off;  
ods html close;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    