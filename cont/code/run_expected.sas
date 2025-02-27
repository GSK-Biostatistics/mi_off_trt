/*******************************************************************************
|
| Program Name   : run_expected.sas
| Program Purpose: Creates the expected values for mean change from baseline for 
|                  each treatment and the treatment difference in mean change
|                  from baseline. 
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

libname summary "/hpawrk/tad66240/repositories/pub_mi_models/final/main/summary";


********************************************************************************;
*** GET NUMBERS OF SUBJECTS DISCONTINUING AT EACH VISIT BASED ON THE SAMPLE  ***;
********************************************************************************;

%let nsubs = 375;

*** 10 PERCENT DISCONTINATIONS ***;
%let nsub10_05 = %sysfunc(floor(0.05*&nsubs.));
%let nsub10_03 = %sysfunc(floor(0.03*&nsubs.));
%let nsub10_02 = %sysfunc(floor(0.02*&nsubs.));

%let psub10_1 = %sysevalf((&nsub10_05.) / &nsubs.);
%let psub10_2 = %sysevalf((&nsub10_05. + &nsub10_03.) / &nsubs.);
%let psub10_3 = %sysevalf((&nsub10_05. + &nsub10_03. + &nsub10_02.) / &nsubs.);


*** 20 PERCENT DISCONTINUATIONS ***;
%let nsub20_10 = %sysfunc(floor(0.10*&nsubs.));
%let nsub20_06 = %sysfunc(floor(0.06*&nsubs.));
%let nsub20_04 = %sysfunc(floor(0.04*&nsubs.));

%let psub20_1 = %sysevalf((&nsub20_10.) / &nsubs.);
%let psub20_2 = %sysevalf((&nsub20_10. + &nsub20_06.) / &nsubs.);
%let psub20_3 = %sysevalf((&nsub20_10. + &nsub20_06. + &nsub20_04.) / &nsubs.);


*** 50 PERCENT DISCONTINUATIONS ***;
%let nsub50_25 = %sysfunc(floor(0.25*&nsubs.));
%let nsub50_15 = %sysfunc(floor(0.15*&nsubs.));
%let nsub50_10 = %sysfunc(floor(0.10*&nsubs.));

%let psub50_1 = %sysevalf((&nsub50_25.) / &nsubs.);
%let psub50_2 = %sysevalf((&nsub50_25. + &nsub50_15.) / &nsubs.);
%let psub50_3 = %sysevalf((&nsub50_25. + &nsub50_15. + &nsub50_10.) / &nsubs.);
/*  */
/* %put &=nsub10_05.; */
/* %put &=nsub10_03.; */
/* %put &=nsub10_02.; */
/*  */
/* %put &=nsub20_10.; */
/* %put &=nsub20_06.; */
/* %put &=nsub20_04.; */
/*  */
/* %put &=nsub50_25.; */
/* %put &=nsub50_15.; */
/* %put &=nsub50_10.; */
/*  */
/* %put &=psub10_1; */
/* %put &=psub10_2; */
/* %put &=psub10_3; */
/*  */
/* %put &=psub20_1; */
/* %put &=psub20_2; */
/* %put &=psub20_3; */
/*  */
/* %put &=psub50_1; */
/* %put &=psub50_2; */
/* %put &=psub50_3; */
/*  */

********************************************************************************;
*** CREATE EXPECTED VALUES FOR EACH SCENARIO                                 ***;
********************************************************************************;
  
data summary.true_means;

  array m_c[4] m_c0-m_c3 (2.14 2.47 2.52 2.54);         *** EXPECTED CONTROL OUTCOME VALUES ***;
  array d_a[4] d_a0-d_a3 (0.00 0.10 0.10 0.10);         *** EXPECTED ACTIVE TREATMENT EFFECT ***;

  array mu_on[4]  mu_on0-mu_on3;
  array mu_off[3] mu_off1-mu_off3;

  *** CREATE TREATMENTS AND SCENARIOS ***;    
  do trtgroup = 1 to 2;
  do scenario = 1 to 2 by 1;        
  do disctype = 1 to 2 by 1;       
  do discrate = 1 to 4 by 1;       

    *** CREATE ON TRT MU AND SD VARIABLES NEEDED FOR WITHDRAWAL MODELS ***;
    do i = 1 to 4;
      mu_on[i] = m_c[i] + (trtgroup=2)*d_a[i];
    end;

    *** CREATE OFF TRT MU FOR TRUE TREATMENT POLICY MU ***;
    do i = 1 to 3;
      select (scenario);
        when (1) mu_off[i] = m_c0;                              *** OFF TRT RETURN TO BASELINE ***;
        when (2) mu_off[i] = mu_on[i+1] + (trtgroup=1)*d_a[i+1];   *** OFF TRT SAME AS ACTIVE     ***;
        otherwise;
      end;
    end;

    *** CREATE TRUE MEANS FOR THE TREATMENT POLICIES ***;
    select (discrate);
      when (1) do;                                *** TW 10% BOTH ARMS (05:03:02) --> (05:08:10) ***;
        mu_true0 = mu_on0;
        mu_true1 = (1-&psub10_1.)*mu_on1 + &psub10_1.*mu_off1;
        mu_true2 = (1-&psub10_2.)*mu_on2 + &psub10_2.*mu_off2;
        mu_true3 = (1-&psub10_3.)*mu_on3 + &psub10_3.*mu_off3;
      end;
      when (2) do;                                *** TW 10% CONTROL 20% ACTIVE ***;
        mu_true0 = mu_on0;
        mu_true1 = (trtgroup=1)*((1-&psub10_1.)*mu_on1 + &psub10_1.*mu_off1) + (trtgroup=2)*((1-&psub20_1.)*mu_on1 + &psub20_1.*mu_off1);
        mu_true2 = (trtgroup=1)*((1-&psub10_2.)*mu_on2 + &psub10_2.*mu_off2) + (trtgroup=2)*((1-&psub20_2.)*mu_on2 + &psub20_2.*mu_off2);
        mu_true3 = (trtgroup=1)*((1-&psub10_3.)*mu_on3 + &psub10_3.*mu_off3) + (trtgroup=2)*((1-&psub20_3.)*mu_on3 + &psub20_3.*mu_off3);
      end;
      when (3) do;                                *** TW 20% BOTH ARMS (10:06:04) --> (10:16:20) ***;
        mu_true0 = mu_on0;
        mu_true1 = (1-&psub20_1.)*mu_on1 + &psub20_1.*mu_off1;
        mu_true2 = (1-&psub20_2.)*mu_on2 + &psub20_2.*mu_off2;
        mu_true3 = (1-&psub20_3.)*mu_on3 + &psub20_3.*mu_off3;
      end;
      when (4) do;                                *** TW 50% BOTH ARMS (25:15:10) --> (25:40:50) ***;
        mu_true0 = mu_on0;
        mu_true1 = (1-&psub50_1.)*mu_on1 + &psub50_1.*mu_off1;
        mu_true2 = (1-&psub50_2.)*mu_on2 + &psub50_2.*mu_off2;
        mu_true3 = (1-&psub50_3.)*mu_on3 + &psub50_3.*mu_off3;
      end;
      otherwise;
    end;
     
    *** CREATE TRUE MEAN CHANGES FROM BASELINE ***;
    z_true1 = mu_true1 - mu_true0;
    z_true2 = mu_true2 - mu_true0;
    z_true3 = mu_true3 - mu_true0;
    
    output;
      
  end;
  end;
  end;
  end;
  
run;  
  


********************************************************************************;
*** CREATE TRUE TREATMENT DIFFERENCE IN MEANS FOR EACH SCENARIO              ***;
********************************************************************************;
  
data summary.true_diffs (drop = trtgroup);
  merge summary.true_means (where = (trtgroup = 1) keep = trtgroup scenario disc: z_: rename = (z_true1 = z_true_c1 z_true2 = z_true_c2 z_true3 = z_true_c3))
        summary.true_means (where = (trtgroup = 2) keep = trtgroup scenario disc: z_: rename = (z_true1 = z_true_a1 z_true2 = z_true_a2 z_true3 = z_true_a3));
  by scenario disctype discrate;
  
  d_true1 = z_true_a1 - z_true_c1;
  d_true2 = z_true_a2 - z_true_c2;
  d_true3 = z_true_a3 - z_true_c3;

run;
  





      
