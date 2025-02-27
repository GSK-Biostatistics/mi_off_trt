/*******************************************************************************
|
| Program Name   : tfl_dif_bias_mcse.sas
| Program Purpose: Table of the LSM Bias MCSE
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

proc format lib = work;
                   
  value scenario 1 = "Return to Baseline"
                 2 = "Same as Active";
                 
  value disctype 1 = "DAR"
                 2 = "DNAR";

  value discrate 1 = "10% Control 10% Active"
                 2 = "10% Control 20% Active"
                 3 = "20% Control 20% Active"
                 4 = "50% Control 50% Active";

  value withrate 1 = "50%"
                 2 = "70%";

  value withtype 1 = "More Early"
                 2 = "Balanced"
                 3 = "More Late";
                 
  value colourcd 1 = "True"
                 2 = "MMRM"
                 3 = "A0-A5"
                 4 = "R1-R2"
                 5 = "U1-U5";

quit;
run;

**********************************************************************************;
*** TRANSPOSE DATA FOR TABLE                                                   ***;
**********************************************************************************;

proc transpose data = summary.dif_bias
               out  = dif_bias_mcse;
  by scenario disctype discrate withrate withtype bias_estimate_n;
  var bias_estimate_stderr;
  id model;
run;

   
**********************************************************************************;
*** CREATE HTML REPORT                                                         ***;
**********************************************************************************;
ods html close;
ods html5 file = "/hpawrk/tad66240/repositories/pub_mi_models/simstudy1/output/tfl_dif_bias_mcse_1000.html";
title1 "Monte Carlo Standard Error of Bias for Treatment Effect";

proc report data = dif_bias_mcse nowd split="#";
  columns scenario disctype discrate withrate withtype bias_estimate_n full mmrm a0 a1 r1 a3 a2 r2 a4 a5 ;

  define scenario / order order=data format=scenario. center "Discontinuation#Scenario";
  define disctype / order order=data format=disctype. center "Discontinuation#Type";
  define discrate / order order=data format=discrate. center "Discontinuation#Rate";
  define withrate / order order=data format=withrate. center "Widthrawal#Rate";
  define withtype / order order=data format=withtype. center "Withdrawal#Type";
  define bias_estimate_n / display "N";
  define full / display format=pvalue8.1 "FULL";
  define mmrm / display format=pvalue8.1 "MMRM";
  define a0 / display format=pvalue8.1 "CICS#(A0)";
  define a1 / display format=pvalue8.1 "OICS#(A1)";
  define r1 / display format=pvalue8.1 "OICS-R#(R1)";
  define a3 / display format=pvalue8.1 "OIOS#(A3)";
  define a2 / display format=pvalue8.1 "PICS#(A2)";
  define r2 / display format=pvalue8.1 "PICS-R#(R2)";
  define a4 / display format=pvalue8.1 "PIOS#(A4)";
  define a5 / display format=pvalue8.1 "PIPS#(A5)";
 
run;

title;  
ods html5 close; 



























