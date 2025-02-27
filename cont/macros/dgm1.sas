/*******************************************************************************
|
| Program Name    : dgm1.sas
| Program Purpose : To generate data to be used in a simulation study which 
|                   investigates multiple imputation strategies for missing 
|                   data using off treatment outcome data to estimate the 
|                   effects of a treatment policy.
| SAS Version     : 9.4
| Created By      : Thomas Drury
| Date            : 20-04-18 
|
|--------------------------------------------------------------------------------
| Terminology: 
| 
| DISCONTINUING FROM TREATMENT
|   When a patient in the trial stops treatment but potentially remains in the 
|   trial and so outcome data continues to be collected and this information is
|   called "Off treatment outcomes".
|
| WITHDRAWING FROM STUDY
|   When a patient leaves the trial and no longer has outcome data collected. 
|   This could be a documented choice, physician decision or they could be 
|   lost to follow up. The outcomes are then missing data.
|
| Data generating process:
| 1.  The data is generated using the same underlying set of on treatment MVN 
|     values for each subject. 
| 2.  The underlying on treatment MVN values are then adjusted by any treatment
|     effects for the scenarios to make patient level active and control data.
| 3.  The full set of on-treatment data are then used to create a set of off
|     treatment values adjusted depending on the treatement scenario.
| 4.  A selection model based on ranking is applied to the on-treatment data 
|     to select the patients that discontinue treatment. 
| 5.  Fixed percentages based on the ranking are flagged as discontinued patients
| 6.  Any patient that discontinues treatment has further on treatment data 
|     replaced with their off-treatment values forming the full treatment policy
|     data.
| 7.  A ranking model is applied at the time of patient discontinuation from 
|     treatment to flag a fixed percentage of patients that withdraw from the study.
| 8.  Any patient that withdraws from the study has further values set as missing.
| 9.  The resulting data is then used for as the observed data for the treatment 
|     policy.
| 10. Simulation study designed so it is not possible to withdrawl (and therefore
|     missing) unless discontinuation from treatment has occured.
|
|----------------------------------------------------------------------------------
| Treatment Discontinuation Selection:
|
|   Omega(j) = 0.5 / SD(j)
|   u ~ Uniform(0,1)
|
|   DAR Measure:  Kappa(j) = Omega(j) * Y_ON(j-1,t) + logit(u)   
|   DNAR Measure: Kappa(j) = Omega(j) * Y_ON(j,t)   + logit(u)
|   
| 1. Kappa(j) is ranked and fixed percentages selected as discontinued patients.
| 2. DAR is when the measure is based on the previous on treatment outcome.
| 3. DNAR is when the measure is based on the current (unobserved) outcome. 
|
|----------------------------------------------------------------------------------
| Trial Withdrawal Selection:
| 
|   Gamma ~ Uniform(0,1)
| 
|   Missing from j onwards | Discontinued at j = Gamma 
|
| 1. Gamma is ranked and fixed percentages selected as patients withdrawn from trial.
| 2. This is an MCAR process for the discontinued patients when the withdrawal 
|    percentage is constant across all timepoints. 
| 3. However if the withdrawal percentage differs across timepoints then the 
|    chance of withdrawal depends on the discontinuation timepoint and is
|    therefore an MAR process. 
|
*********************************************************************************/;

**********************************************************************************;
***                                                                            ***;
*** SECTION 1: CREATE PARALLEL CODE IN MACRO TO CALL IN MULTIPLE SESSIONS      ***;
***                                                                            ***;
**********************************************************************************;

%macro dgm1(part=, nsims=, nsubs=, simseed=);

**********************************************************************************;
*** STEP 0: ADMIN FOR PARALLEL PROCESSING                                      ***;
**********************************************************************************;

%let dgmseed = %sysevalf(&simseed. + &ms_n.);
%let part    = %sysfunc(putn(&part.,z2.));
%let sess    = %sysfunc(putn(&ms_n.,z2.));

%put &=dgmseed.;

options nofmterr cpucount = 2;

libname data "/hpawrk/tad66240/repositories/pub_mi_models/final/main/data";

%ods_off();



**********************************************************************************;
*** STEP 1: DEFINE OCS AND SCENARIOS                                           ***;
**********************************************************************************;

*** DEFINE SCENARIO VARIABLE DECODES ***;
proc format library = work;

  value trtgroup 1 = "Control"
                 2 = "Active";

  value scenario 1 = "Off Treatment Return To Baseline"
                 2 = "Off Treatment Same as Active";
               
  value disctype 1 = "DAR" 
                 2 = "DNAR";

  value discrate 1 = "10% Control 10% Active"
                 2 = "10% Control 20% Active"
                 3 = "20% Control 20% Active"
                 4 = "50% Control 50% Active";
              
  value withtype 1 = "Early"
                 2 = "Balanced"
                 3 = "Late";

  value withrate 1 = "50%"
                 2 = "70%";
             
run;



**********************************************************************************;
*** STEP 2: SIMULATE DATA FOR SCENARIOS                                        ***;
**********************************************************************************;

proc iml;

 m_c = {2.14, 2.47, 2.52, 2.54};
 v_c = {0.45 0.46 0.46 0.47,
        0.46 0.66 0.62 0.63,
        0.46 0.62 0.65 0.63,
        0.47 0.63 0.63 0.68};   

 call randseed(&dgmseed.);

 sub = colvec(repeat(t(1:&nsubs.), &nsims.));    *** CREATE SUBJECT VECTOR ***;
 sim = colvec(repeat(t(1:&nsims.), 1, &nsubs.)); *** CREATE SIMULATION VECTOR ***;

 trt = colvec(repeat(1, &nsims.*&nsubs.));         *** CREATE CONTROL TREATMENT VECTOR ***;        
 y_c = randnormal(&nsims.*&nsubs., m_c, v_c);      *** CREATE CONTROL DATA VECTOR FOR CONTROL ***;
 mvn1 = (trt || sim || sub || y_c);        

 trt = colvec(repeat(2, &nsims.*&nsubs.));         *** CREATE ACTIVE TREATMENT VECTOR ***; 
 y_c = randnormal(&nsims.*&nsubs., m_c, v_c);      *** CREATE CONTROL DATA VECTOR FOR ACTIVE ***;
 mvn2 = (trt || sim || sub || y_c);        

 m_c  = repeat(t(m_c), &nsims.*&nsubs.);           
 v_c  = repeat(rowvec(vecdiag(v_c)), &nsims.*&nsubs.);

 mvn1 = (mvn1 || m_c || v_c);        
 mvn2 = (mvn2 || m_c || v_c);        
 mvn  = mvn1 // mvn2;
 
 create simulations1 from mvn[c={"trtgroup" "sim" "sub" 
                                 "y_c0" "y_c1" "y_c2" "y_c3" 
                                 "m_c0" "m_c1" "m_c2" "m_c3" 
                                 "v_c0" "v_c1" "v_c2" "v_c3"}];  
 append from mvn;

quit;


*** CREATE ON AND OFF TREATMENT DATA WITH HETROGENEITY ***;
data simulations2;
  set simulations1;

  all      = 1;

  array y_c[4] y_c0-y_c3;  
  array m_c[4] m_c0-m_c3; 
  array v_c[4] v_c0-v_c3;
  array d_a[4] d_a0-d_a3 (0.00 0.10 0.10 0.10);   *** EXPECTED ACTIVE TREATMENT EFFECT ***;
 
                              
  array y_on [4] y_on0-y_on3;             *** ON TREATMENT OUTCOMES ***;    
  array mu_on[4] mu_on0-mu_on3;           *** MU ON TREATMENT - PARAMETERS USED IN TW MODEL ***; 
  array sd_on[4] sd_on0-sd_on3;           *** SD ON TREATMENT - PARAMETERS USED IN TW MODEL ***;                      

  array y_off [3] y_off1-y_off3;          *** OFF TREATMENT OUTCOMES ***; 
  array mu_off[3] mu_off1-mu_off3;        *** MU OFF TREATMENT ***; 

  u_sd = 0.3*rand("normal",0,1);          *** ON TREATMENT HETROGENEITY ***;       
  v_sd = 0.3*rand("normal",0,1);          *** OFF TREATMENT HETROGENEITY ***;


  do scenario = 1 to 2 by 1;       *** SCENARIOS FOR OFF TREATMENT BEHAVIOUR: RTB OR SAA ***; 
  do disctype = 1 to 2 by 1;       *** DISCONTINUATION TYPE: DAR / DNAR ***;
  do discrate = 1 to 4 by 1;       *** DISCONTINUATION RATES: 10:10 10:20 20:20 50:50 ***;
  
 
    *** CREATE UNIQUE SUBJECT NUMBER ***;
    subjid = ifn(trtgroup=1, 100*&nsims.+sub, 200*&nsims.+sub); 

    *** CREATE ON TREATMENT DATA ***;
    do i = 1 to 4;
      y_on[i] = y_c[i] + (trtgroup=2)*d_a[i] + u_sd;      
    end;

    *** CREATE OFF TREATMENT DATA ***;
    do i = 1 to 3;
      select (scenario);
        when (1) y_off[i] = y_on[i+1] - m_c[i+1] - (trtgroup=2)*d_a[i+1] + m_c0 + v_sd; 
        when (2) y_off[i] = y_on[i+1] + (trtgroup=1)*d_a[i+1] + v_sd;
        otherwise;
      end;
    end;

    *** CREATE ON TRT MU AND SD VARIABLES NEEDED FOR DISCONTINUATION SELECTION ***;
    do i = 1 to 4;
      mu_on[i] = m_c[i] + (trtgroup=2)*d_a[i];
      sd_on[i] = sqrt(v_c[i]);
    end;

    output;

  end;
  end;
  end;

run;

proc sort data = simulations2;
  by all sim sub trtgroup scenario disctype discrate;
run;


**********************************************************************************;
*** STEP 3: FLAG TREATMENT DISCONTINUATIONS                                    ***;
**********************************************************************************;


*** CREATE SCORES FOR ALL TIMEPOINTS ***;
data simulations3;
  set simulations2;
  by all sim sub trtgroup scenario disctype discrate;

  *** EXPLICIT OMEGA1 PARAMETERS - SAME FOR BOTH TREATMENTS AND ALL DISCONTINUATION RATES ***;
  omega1_0 = 0.5 / sd_on0;
  omega1_1 = 0.5 / sd_on1;
  omega1_2 = 0.5 / sd_on2;
  omega1_3 = 0.5 / sd_on3;

  u1 = rand("uniform");
  u2 = rand("uniform");
  u3 = rand("uniform");

  *** CREATE DISCONTINUATION SCORE AT EACH TIMEPOINT EITHER DAR OR DNAR ***;
  select(disctype);
    when (1) do;
      kappa1 = omega1_1*y_on0 - log(u1/(1-u1)); 
      kappa2 = omega1_2*y_on1 - log(u2/(1-u2));
      kappa3 = omega1_3*y_on2 - log(u3/(1-u3));
    end;
    when (2) do;
      kappa1 = omega1_1*y_on1 - log(u1/(1-u1)); 
      kappa2 = omega1_2*y_on2 - log(u2/(1-u2));
      kappa3 = omega1_3*y_on3 - log(u3/(1-u3));    
    end;
    otherwise;
  end;

run;


*** SORT FOR RANKING ***;
proc sort data = simulations3
          out  = simulations4;
  by all sim trtgroup scenario disctype discrate sub;
run;


*** RANK FIRST TIMEPOINT BASED ON KAPPA1 ***;
proc rank data =  simulations4
          out  =  disc_rankings1;
  by all sim trtgroup scenario disctype discrate;
  var kappa1;
  ranks discrank1;
run;


*** REMOVE SUBJECTS FROM FIRST TIMEPOINT BASED ON DISC RATE ***;
data disc_rankings1;
  set disc_rankings1;
  
  *** TIMEPOINT 1 - LOWEST RANKS REMOVED ***;
  if (discrate = 1 and ( (trtgroup=1 and discrank1 le floor(0.05*&nsubs.)) or (trtgroup=2 and discrank1 le floor(0.05*&nsubs.)) )) or
     (discrate = 2 and ( (trtgroup=1 and discrank1 le floor(0.05*&nsubs.)) or (trtgroup=2 and discrank1 le floor(0.10*&nsubs.)) )) or
     (discrate = 3 and ( (trtgroup=1 and discrank1 le floor(0.10*&nsubs.)) or (trtgroup=2 and discrank1 le floor(0.10*&nsubs.)) )) or
     (discrate = 4 and ( (trtgroup=1 and discrank1 le floor(0.25*&nsubs.)) or (trtgroup=2 and discrank1 le floor(0.25*&nsubs.)) )) then delete;  

run;


*** RANK SECOND TIMEPOINT CONDITIONAL ON BEING ON TREATMENT ***;
proc rank data =  disc_rankings1
          out  =  disc_rankings2;
  by all sim trtgroup scenario disctype discrate;
  var kappa2;
  ranks discrank2;
run;


*** REMOVE SUBJECTS FROM SECOND TIMEPOINT BASED ON DISC RATE ***;
data  disc_rankings2;
  set  disc_rankings2;

 *** TIMEPOINT 2 - LOWEST RANKS REMOVED ***;  
 if (discrate = 1 and ( (trtgroup=1 and discrank2 le floor(0.03*&nsubs.)) or (trtgroup=2 and discrank2 le floor(0.03*&nsubs.)) )) or
    (discrate = 2 and ( (trtgroup=1 and discrank2 le floor(0.03*&nsubs.)) or (trtgroup=2 and discrank2 le floor(0.06*&nsubs.)) )) or
    (discrate = 3 and ( (trtgroup=1 and discrank2 le floor(0.06*&nsubs.)) or (trtgroup=2 and discrank2 le floor(0.06*&nsubs.)) )) or
    (discrate = 4 and ( (trtgroup=1 and discrank2 le floor(0.15*&nsubs.)) or (trtgroup=2 and discrank2 le floor(0.15*&nsubs.)) )) then delete;

run;


*** RANK THIRD TIMEPOINT CONDITIONAL ON BEING ON TREATMENT ***;
proc rank data =  disc_rankings2
          out  =  disc_rankings3;
  by all sim trtgroup scenario disctype discrate;
  var kappa3;
  ranks discrank3;
run;


*** REMOVE SUBJECTS FROM THIRD TIMEPOINT BASED ON DISC RATE ***;
data  disc_rankings3;
  set  disc_rankings3;
  
  *** TIMEPOINT 3 - LOWEST RANKS REMOVED ***;
  if (discrate = 1 and ( (trtgroup=1 and discrank3 le floor(0.02*&nsubs.)) or (trtgroup=2 and discrank3 le floor(0.02*&nsubs.)) )) or
     (discrate = 2 and ( (trtgroup=1 and discrank3 le floor(0.02*&nsubs.)) or (trtgroup=2 and discrank3 le floor(0.04*&nsubs.)) )) or
     (discrate = 3 and ( (trtgroup=1 and discrank3 le floor(0.04*&nsubs.)) or (trtgroup=2 and discrank3 le floor(0.04*&nsubs.)) )) or
     (discrate = 4 and ( (trtgroup=1 and discrank3 le floor(0.10*&nsubs.)) or (trtgroup=2 and discrank3 le floor(0.10*&nsubs.)) )) then delete;

run;



**********************************************************************************;
*** STEP 4: CREATE ON AND OFF TREATMENT DATA                                   ***;
**********************************************************************************;


*** MERGE ON SUBJECTS COMPLETING EACH VISIT AND CREATE TRT DISC FLAGS ***;
data  simulations5;
  merge  simulations4  
         disc_rankings1 (in = on1 keep = all sim trtgroup scenario disctype discrate sub)
         disc_rankings2 (in = on2 keep = all sim trtgroup scenario disctype discrate sub)
         disc_rankings3 (in = on3 keep = all sim trtgroup scenario disctype discrate sub);
  by all sim trtgroup scenario disctype discrate sub;

  if not on1 then disctime = 0;
  else if not on2 then disctime = 1;
  else if not on3 then disctime = 2;
  else disctime = 3;

  d0 = 0;
  d1 = ifn(on1, 0, 1);
  d2 = ifn(on2, 0, 1);
  d3 = ifn(on3, 0, 1);

  dtime0 = d0;
  dtime1 = 1 - d1;
  dtime2 = 2 - d2 - d1;
  dtime3 = 3 - d3 - d2 - d1;  

  *** CREATE TRUE OUTCOMES ***;
  y_true0 = y_on0;
  y_true1 = ifn(d1=0, y_on1, y_off1);
  y_true2 = ifn(d2=0, y_on2, y_off2);
  y_true3 = ifn(d3=0, y_on3, y_off3);
        
run;


/* *** SORT FOR CHECKS ***; */
/* proc sort data =  simulations5 */
/*           out  =  disc_checks0; */
/*   by all trtgroup scenario disctype discrate; */
/* run; */
/*  */
/* *** CHECK ROUGH NUMBERS ACCROSS SIMULATIONS ***; */
/* proc freq data =  disc_checks0 noprint; */
/*   by all trtgroup scenario disctype discrate; */
/*   tables disctime     / out = disc_checks1; */
/*   tables sim*disctime / out = disc_checks2; */
/* run; */


**********************************************************************************;
*** STEP 5: FLAG TRIAL WITHDRAWALS                                             ***;
**********************************************************************************;

*** SORT BY DISCTIME ***;
proc sort data =  simulations5
          out  =  simulations6;
  by all sim trtgroup scenario disctype discrate disctime sub;
run;

*** KEEP ONLY SUBJECTS THAT TREATMENT DISCONTINUE AND CREATE WITHDRAWAL SCORE ***;
data  simulations7;
  set  simulations6;
  where disctime lt 3; 
  gamma = rand("uniform"); 
run;

*** CREATE SUBJECT RANKING BASED ON GAMMA ***;
proc rank data =  simulations7 
          out  =  with_rankings1
          percent;
  by all sim trtgroup scenario disctype discrate disctime;
  var gamma;
  ranks withrank;
run;



**********************************************************************************;
*** STEP 6: CREATE MISSING DATA                                                ***;
**********************************************************************************;

data  simulations8;
  merge  simulations6  
         with_rankings1 (in = offtrt keep = all sim trtgroup scenario disctype discrate disctime sub withrank);

  by all sim trtgroup scenario disctype discrate disctime sub;      

  do withrate = 1 to 2 by 1;  
  do withtype = 1 to 3 by 1;
     
    if offtrt and 
       disctime = 0 and ( (withrate = 1 and withtype=1 and withrank le 70) or 
                          (withrate = 1 and withtype=2 and withrank le 50) or 
                          (withrate = 1 and withtype=3 and withrank le 30) or
                          (withrate = 2 and withtype=1 and withrank le 90) or 
                          (withrate = 2 and withtype=2 and withrank le 70) or 
                          (withrate = 2 and withtype=3 and withrank le 50) ) then do;

      withtime = 0;
      w0 = 0;
      w1 = 1;
      w2 = 1;
      w3 = 1;
    
      y0 = y_true0;
      y1 = .A;
      y2 = .A;
      y3 = .A; 
    
    end;
    else if offtrt and
       disctime = 1 and ( (withrate = 1 and withtype=1 and withrank le 30) or 
                          (withrate = 1 and withtype=2 and withrank le 50) or 
                          (withrate = 1 and withtype=3 and withrank le 70) or
                          (withrate = 2 and withtype=1 and withrank le 50) or 
                          (withrate = 2 and withtype=2 and withrank le 70) or 
                          (withrate = 2 and withtype=3 and withrank le 90) ) then do;
      withtime = 1;
      w0 = 0;
      w1 = 0;
      w2 = 1;
      w3 = 1;
    
      y0 = y_true0;
      y1 = y_true1;
      y2 = .B;
      y3 = .B; 
    
    end;
    else if offtrt and
       disctime = 2 and ( (withrate = 1 and withtype=1 and withrank le 30) or 
                          (withrate = 1 and withtype=2 and withrank le 50) or 
                          (withrate = 1 and withtype=3 and withrank le 70) or
                          (withrate = 2 and withtype=1 and withrank le 50) or 
                          (withrate = 2 and withtype=2 and withrank le 70) or 
                          (withrate = 2 and withtype=3 and withrank le 90) ) then do;
      withtime = 2;
      w0 = 0;
      w1 = 0;
      w2 = 0;
      w3 = 1;
    
      y0 = y_true0;
      y1 = y_true1;
      y2 = y_true2;
      y3 = .C; 
    
    end;
    else do;
    
      withtime = 3;
      w0 = 0;
      w1 = 0;
      w2 = 0;
      w3 = 0;
    
      y0 = y_true0;
      y1 = y_true1;
      y2 = y_true2;
      y3 = y_true3; 
    
    end;
       
    wtime0 = w0;
    wtime1 = 1 - w1;
    wtime2 = 2 - w2 - w1;
    wtime3 = 3 - w3 - w2 - w1;     
    
    output;
           
  end;
  end;
     
run;     
     
     
/* *** SORT FOR CHECKING ***; */
/* proc sort data =  simulations8 */
/*           out  =  with_checks0; */
/*   by all trtgroup scenario disctype discrate withrate withtype; */
/* run; */
/*  */
/* *** CHECK ROUGH NUMBERS ACCROSS SIMULATIONS ***; */
/* proc freq data =  with_checks0 (where=(disctime < 3)) noprint; */
/*  by all trtgroup scenario disctype discrate withrate withtype; */
/*  tables withtime     / out = with_checks1; */
/*  tables sim*withtime / out = with_checks2; */
/* run; */



**********************************************************************************;
*** STEP 7: CREATE SLIMMER FINAL SIMULATION DATASET                            ***;
**********************************************************************************;


proc sql noprint;
  create table simulations as
    select scenario, disctype, discrate, withrate, withtype, 
           sim, trtgroup, sub, subjid,
           disctime, d0, d1, d2, d3, dtime1, dtime2, dtime3,
           withtime, w0, w1, w2, w3, wtime1, wtime2, wtime3,
           y0, y1, y2, y3,
           y_on0, y_on1, y_on2, y_on3,
           y_off1, y_off2, y_off3,
           y_true0, y_true1, y_true2, y_true3
    from  simulations8
    order by scenario, disctype, discrate, withrate, withtype,
             sim, trtgroup, sub, subjid;
quit;
run;



**********************************************************************************;
*** STEP 8: SAVE A COPY OF THE DATA IN DATA FOLDER                             ***;
**********************************************************************************;

data data.simstudy1_part&part._sess&sess.;
  set simulations;
  by scenario disctype discrate withrate withtype
     sim trtgroup sub subjid;    
  
  nsubs   = &nsubs.;
  nsims   = &nsims.;
  dgmseed = &dgmseed.;
  part    = &part.;

  scenario_lbl = put(scenario,scenario.);
  disctype_lbl = put(disctype,disctype.); 
  discrate_lbl = put(discrate,discrate.); 
  withrate_lbl = put(withrate,withrate.);  
  withtype_lbl = put(withtype,withtype.);
  trtgroup_lbl = put(trtgroup,trtgroup.); 
      
run;


**********************************************************************************;
*** STEP 9: CLEAN UP WORK AREA                                                 ***;
**********************************************************************************;

proc datasets lib = work nolist;
 delete simulations simulations1-simulations8 
        disc_rankings1-disc_rankings3 disc_checks: 
        with_rankings1 with_checks:;
quit;
run;

%ods_on();

%mend dgm1;

