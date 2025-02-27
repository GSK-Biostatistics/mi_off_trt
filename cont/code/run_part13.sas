/*******************************************************************************
|
| Program Name:    run_part13.sas
| Program Purpose: Driver to call components for part of sim study.
| SAS Version:     9.4
| Created By:      Thomas Drury
| Date:            20-04-18 
|
|-------------------------------------------------------------------------------
| Notes: 
| This code uses parallel processing via the ms_tools macro library.
| It uses 25 parallel sessions to run small numbers of sims rapidly.
|
*******************************************************************************/;


%let p=13;


*** INCLUDE USEFUL TOOLS ***;
%inc "/hpawrk/tad66240/repositories/sim_tools/sim_tools.sas";
%inc "/hpawrk/tad66240/repositories/ms_tools/ms_tools.sas";


*** INCLUDE SIM STUDY CODE ***;
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/dgm1.sas";
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/full.sas";
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/mmrm.sas";
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/mi_a.sas";
%inc "/hpawrk/tad66240/repositories/pub_mi_models/final/main/macros/mi_r.sas"; 

options nomprint nomerror;
%start_time(startid=PART&p.);

%ms_signon(sess_n=-25);
%ms_macrocall(macro_name=dgm1, mparm_list=%str(part=&p., nsims=2, nsubs=375, simseed=&p.0000), keep_list=NONE, sign_off=N);
%ms_macrocall(macro_name=full, mparm_list=%str(part=&p.), keep_list=NONE, sign_off=N);
%ms_macrocall(macro_name=mmrm, mparm_list=%str(part=&p.), keep_list=NONE, sign_off=N);
%ms_macrocall(macro_name=mi_a, mparm_list=%str(part=&p., nimps=25, impseed=&p.0000), keep_list=NONE, sign_off=N);
%ms_macrocall(macro_name=mi_r, mparm_list=%str(part=&p., nimps=25, impseed=&p.0000), keep_list=NONE, sign_off=Y); 

%stop_time(startid=PART&p.);











