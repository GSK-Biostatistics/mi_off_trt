/*******************************************************************************
| Program Name    : cox_posttreat.sas
| Program Purpose : Implements multiple imputation for time to event data 
|                   using Cox imputation and analysis models
| SAS Version     : 9.4  
| Created By      : Ben Hartley 
|-------------------------------------------------------------------------------
| Licence: MIT: Copyright 2021 Ben Hartley & GlaxoSmithKline LLC
|
| Permission is hereby granted, free of charge, to any person obtaining a copy
| of this software and associated documentation files (the "Software"), to deal
| in the Software without restriction, including without limitation the rights
| to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
| copies of the Software, and to permit persons to whom the Software is
| furnished to do so, subject to the following conditions:
|
| The above copyright notice and this permission notice shall be included in all
| copies or substantial portions of the Software.
|
| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
| IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
| FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
| AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
| LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
| OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
| SOFTWARE.
|
********************************************************************************/;

********************************************************************************;
*** CREATE ANALYSIS MACRO                                                    ***;
********************************************************************************;

%macro cox_posttreat(seed         = 0,     /*seed used for both (a) boostrapping, (b) generating random uniform variates*/
                     dsin         = ,      /*name of the input dataset - see exampledata1 for format required*/
                     impModel     = ,      /*imputation model style (a) T (MAR or J2R or single post-treatment regimen), (b) TbyP (full interaction), or (c) TP (shift down)*/
                     dsoutLabel   = ,      /*label suffix for output dataset*/
                     nImp         = ,      /*number of imputations to use*/
                     imputeFlag   = ,      /*subject level binary flag variable: 1 to impute, 0 otherwise*/
                     imputeMax    = ,      /*maximum possible time point to impute up to, must be smaller or equal to largest time in dataset*/
                     startVar     = ,      /*variable containing start time of period in counting process*/
                     stopVar      = ,      /*variable containing stop time of period in counting process*/
                     cnsrVar      = ,      /*censoring variable: 1 for censored, 0 for event*/
                     periodVar    = ,      /*period variable: 1 for on-treatment, 2 for off-treatment*/
                     patID        = ,      /*unique subject ID variable*/
                     ContCov      = ,      /*list of continuous covariate variables*/
                     CatCov       = ,      /*list of categorical covariate variables*/
                     impTreatCov  = ,      /*variable containing treatment which will be assumed for the missing data imputation*/
                     randTreatCov = ,      /*variable containing randomised treatment, must be a different variable (values may be the same)*/
                     tiesimpute   = ,      /*SAS phreg method to use for ties in imputation model*/
                     tiesanalysis = ,      /*SAS phreg method to use for ties in analysis models*/
                     debug        = 0);    /*binary variable: 1 to debug, 0 to run code deleting intermediate datasets*/

  proc sql;
  select
    strip(put(count(unique &patID.), best.)),
    strip(put(count(&patID.), best.)),
    strip(put(max(&stopVar.), best.)),
    strip(put(countw("&ContCov."), best.)),
    strip(put(countw("&CatCov."), best.))
  into
    :nPat,
    :nObs,
    :stopVarMax,
    :nContCov,
    :nCatCov
  separated by ""
  from &dsin.
  ;
  quit;

  *Normalise continuous covariates and create dummy variables for categorical covariates;
  ods output columnnames=nTreat;
    proc glimmix data=&dsin. outdesign(names novar X=_TREAT)=DesignMat1 nofit noclprint;
      class &impTreatCov.;
      model &stopVar.=&impTreatCov. / noint;
      id &patID. &periodVar. &startVar. &stopVar. &cnsrVar. &imputeFlag. &randTreatCov. &impTreatCov. &CatCov. &ContCov.;
    run;
  ods output close;
  
  data _null_;
  set nTreat;
    call symputx("nTreat", _N_);
  run;
  
  ods output columnnames=nPeriod;
    proc glimmix data=&dsin. outdesign(names novar X=_PERIOD)=DesignMat2 nofit noclprint;
      class &PeriodVar.;
      model &stopVar.=&PeriodVar. / noint;
      id &patID. &periodVar.;
    run;
  ods output close;
  
  data _null_;
  set nPeriod;
    call symputx("nPeriod", _N_);
  run;
  
  ods output columnnames=nCat;
    proc glimmix data=&dsin. outdesign(names novar X=_CAT)=DesignMat3 nofit noclprint;
      class &CatCov.;
      model &stopVar.=&CatCov. / noint;
      id &patID. &periodVar.;
    run;
  ods output close;
  
  data _null_;
  set nCat;
    call symputx("nCat", _N_);
  run;
  
  ods output columnnames=nCont;
    proc glimmix data=&dsin. outdesign(names novar X=_CONT)=DesignMat4 nofit noclprint;
      model &stopVar.=&ContCov. / noint;
      id &patID. &periodVar.;
    run;
  ods output close;
  
  data _null_;
  set nCont;
    call symputx("nCont", _N_);
  run;
  
  data DesignMat5;
  merge DesignMat1 DesignMat2 DesignMat3 DesignMat4;
    by &patID. &periodVar.;
    %do i=1 %to &nTreat.;
      %do j=1 %to &nPeriod;
        _INT_TREAT&i._PERIOD&j.=_TREAT&i.*_PERIOD&j.;
      %end;
    %end;
  run;
  
  proc standard data=DesignMat5 out=DesignMat6 mean=0 std=1;
    var _CONT:;
  run;
  
  data SourceData1;
  set DesignMat6;
  run;
  
  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete DesignMat1 DesignMat2 DesignMat3 DesignMat4 DesignMat5 DesignMat6 nTreat nCat nCont nPeriod; quit;
  %end;
  
  *Bootstrap the sample to get an empirical distribution for the baseline hazard function - use cluster bootstrapping;
  proc surveyselect data=SourceData1 method=URS reps=&nImp. n=&npat. outhits out=bootstrap1 seed=&seed.;
    samplingunit &patID.;
  run;
  quit;
  
  *Create the baseline hazard function using zero values for all covariates;
  data covars1;
    array _TREAT[&nTreat.] (&nTreat.*0);
    array _CAT[&nCat.] (&nCat.*0);
    array _CONT[&nCont.] (&nCont.*0);
    array _PERIOD[&nPeriod.] (&nPeriod.*0);
    %do i=1 %to &nTreat.; %do j=1 %to &nPeriod; _INT_TREAT&i._PERIOD&j.=0; %end; %end;
    output;
  run;
  
  *Cox proportional hazards model on bootstraped results to obtain baseline hazard ratios;
  *There is no need to use the robust standard error since we only sample point estimates from this model which are unchanged by the robust sandwich SE;
  proc phreg data=bootstrap1 outest=est1(drop=_TIES_ _TYPE_ _STATUS_ _NAME_ _LNLIKE_) fast;
    by Replicate;
    baseline out=baseline1 covariates=covars1 survival=SURVIVAL cumhaz=CUMHAZ xbeta=XBETA;
    %if &impModel.=T %then %do;
      model (&startVar., &stopVar.)*&cnsrVar.(1)=_TREAT: _CAT: _CONT: / ties=&tiesimpute.;
    %end;
    %if &impModel.=TP %then %do;
      model (&startVar., &stopVar.)*&cnsrVar.(1)=_TREAT: _PERIOD: _CAT: _CONT: / ties=&tiesimpute.;
    %end;
    %if &impModel.=TbyP %then %do;
      model (&startVar., &stopVar.)*&cnsrVar.(1)=%do i=1 %to &nTreat.; %do j=1 %to &nPeriod; _INT_TREAT&i._PERIOD&j. %end; %end; _CAT: _CONT: / ties=&tiesimpute.;
    %end;
  run;
  
  *Estimates of regression coefficients from analysis on bootstrapped sample;
  data est2;
  set est1;
    _TYPE_="SCORE";
    _NAME_="Predict";
  run;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete est1 bootstrap1 covars1; quit;
  %end;

  proc score data=SourceData1 score=est2 out=linpred1;
  by replicate;
  run;

  data linpred2;
  set linpred1;
    call streaminit(&seed.);
    U=rand("UNIFORM");
    CUTOFF=-log(U)*exp(-Predict);
  run;

  *In selecting lines to be imputed and lines not to be imputed, only the latest period is relevant;
  proc sql;
  create table linpred3 as select *
  from linpred2
  group by Replicate, &PatID.
  having &stopVar.=max(&stopVar) and &startVar.=max(&startVar)
  ;
  quit;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete SourceData1 linpred1 linpred2; quit;
  %end;

  *Select the baseline hazard function estimates from the sample into a dataset;
  data baseline2;
  set baseline1;
    CUMBASEHAZ=CUMHAZ/exp(XBETA);
    _PREV=lag(CUMBASEHAZ);
    BASEHAZ=CUMBASEHAZ-_PREV;
    if &stopVar.=0 then delete;
    drop _CONT: _CAT: _TREAT: _PERIOD: XBETA SURVIVAL CUMHAZ _PREV;
  run;

  *Here I add a row to each imputation with a time beyond the max imputation time;
  *This row is simply so that patients do not drop out of the analysis later if they drop out late and; 
  *a particular bootstrap has no hazard function estimates later than their dropout.;
  *The row I add has no risk associated - I set the hazard to 0 and the cumhazard to the previous value.;

  data baseline3;
  set baseline2;
    by Replicate &stopVar.;
    output;
    if last.Replicate then do;
      &stopVar.=&stopVarMax.+1;
      BASEHAZ=0;
      output;
    end;
  run;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete est2 baseline1 baseline2; quit;
  %end;

  *Merge baseline hazard function onto lin pred dataset;
  proc sql;
    create table haz1 as select
      a.Replicate,
      a.&patID.,
      a.&randTreatCov.,
      %do i=1 %to &nCatCov.; a.%scan(&CatCov., &i.) , %end;
      %do i=1 %to &nContCov.; a.%scan(&ContCov., &i.) , %end;
      %do i=1 %to &nCat.; a._CAT&i., %end;
      %do i=1 %to &nCont.; a._CONT&i., %end;
      a.&stopVar. as LASTDAY "",
      a.&cnsrvar.,
      a.&imputeFlag.,
      b.&stopVar.,
      b.BASEHAZ,
      a.CUTOFF
    from linpred3(where=(&imputeFlag.=1)) a inner join baseline3 b on a.Replicate=b.Replicate
    where b.&stopVar. gt a.&stopVar.
    order by a.Replicate, a.&patID., b.&stopVar.
    ;
  quit;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete baseline3; quit;
  %end;

  *Calculate the hazard which imputed failure times will be drawn from;
  data haz2;
  set haz1;
    retain CUMBASEHAZ;
    by Replicate &patID. &stopVar.;
    if first.&patID. then do;
      CUMBASEHAZ=BASEHAZ;
    end;
    else do;
      CUMBASEHAZ=CUMBASEHAZ+BASEHAZ;
    end;
  run;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete haz1; quit;
  %end;

  *Obtain imputed failure times;
  data haz_ev;
  set haz2 (where=(CUMBASEHAZ ge CUTOFF));
    by Replicate &patID. &stopVar.;
    if first.&patID. then output;
    keep Replicate &patID. _CONT: _CAT: &randTreatCov. &ContCov. &CatCov. &imputeFlag. &stopVar.;
  run;

  data haz_all;
  set haz2;
    by Replicate &patID. &stopVar.;
    if first.&patID. then output;
    keep Replicate &patID. _CONT: _CAT: &randTreatCov. &ContCov. &CatCov. &imputeFlag.;
  run;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete haz2; quit;
  %end;

  data imp1;
  merge haz_all haz_ev(in=ev);
    by Replicate &patID.;
    if ev then do;
      if &stopVar. le &imputeMax. then do;
        &cnsrVar.=0;
      end;
      if &stopVar. gt &imputeMax. then do;
        &cnsrVar.=1;
        &stopVar.=&imputeMax.;
      end;
    end;
    else do;
      &cnsrVar.=1;
      &stopVar.=&imputeMax.;
    end;
  run;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete haz_all haz_ev; quit;
  %end;

  data nonimp1;
  set linpred3(where=(&imputeFlag. ne 1));
    drop &periodVar. &startVar. &impTreatCov. _PERIOD: _TREAT: _INT: Predict U CUTOFF;
  run;

  data imputed0;
  set imp1 nonimp1;
  run;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete imp1 nonimp1 linpred3; quit;
  %end;

  proc sort data=imputed0 out=imputed1; by Replicate; run;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete imputed0; quit;
  %end;

  *Find the average number of events to present this information;
  proc freq data=imputed1;
    tables &randTreatCov.*&cnsrVar. / out=props1 outpct;
  run;

  data props2;
  set props1;
    MEAN_EVENTS=COUNT/(&nImp.);
    PCT_EVENTS=PCT_ROW;
    NImpute=&nImp.;
    keep &randTreatCov. &cnsrVar. MEAN_EVENTS PCT_EVENTS;
  run;

  *Run Cox proportional hazards model on each imputed dataset;
  ods output diffs=diffs1;
    proc phreg data=imputed1 fast;
      by Replicate;
      class &randTreatCov. &CatCov. / param=glm;
      model &stopVar.*&cnsrVar.(1)=&randTreatCov. &CatCov. &ContCov. / ties=&tiesanalysis.;
      lsmeans &randTreatCov. / cl diff;
    run;
  ods output close;

  *Delete datasets which are not going to be used to save some memory;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete imputed1; quit;
  %end;

  *Reverse the comparisons so that all are available;
  data revdiffs;
  set diffs1(rename=(&randTreatCov.=_&randTreatCov. _&randTreatCov.=&randTreatCov. Upper=Lower Lower=Upper));
    Estimate=-Estimate;
    Upper=-Upper;
    Lower=-Lower;
  run;

  data diffs2;
  set diffs1 revdiffs;
  run;

  proc sort data=diffs2;
    by &randTreatCov. _&randTreatCov.;
  run;

  *Combine results with Rubin rules, can specify EDF here if complete dataset is small;
  ods output parameterestimates=res1;
    proc mianalyze data=diffs2 alpha=0.05;
      by &randTreatCov. _&randTreatCov.;
      modeleffects Estimate;
      stderr StdErr;
    run;
  ods output close;

  data Result_&dsoutLabel.;
  set res1(in=hr);
    HazardRatio=exp(Estimate);
    LowerHR=exp(LCLMean);
    UpperHR=exp(UCLMean);
  run;

  data Props_&dsoutLabel.;
  set props2;
  run;

  *Delete remaining datasets;
  %if &debug.=0 %then %do;
    proc datasets lib=work; delete diffs1 revdiffs diffs2 res1 props1 props2; quit;
  %end;
%mend;


********************************************************************************;
*** EXAMPLE USE WITH SIMULATED DATA                                          ***;
***                                                                          ***;
*** The example dataset has one row per period regardless of whether there   ***;
*** is any data observed in the period, i.e. it is possible that START=STOP  ***;
*** for PERIOD=2 if there is no off-treatment data but the row is still in   ***;
*** the dataset.                                                             ***;
***                                                                          ***;
*** For Period 1, use IMPTREAT=RANDTREAT                                     ***;
*** For Period 2:                                                            ***;
*** (i) For the "T" imputation model, can use 99 as code for "off-treatment" ***; 
***     but can also set IMPTREAT=1 for J2R, or IMPTREAT=RANDTREAT for MAR   ***;
*** (ii)For the "TP" or "TbyP" imputation models, set IMPTREAT=RANDTREAT     ***;
*** IMPTREAT could also depend on reason for WD                              ***;
***                                                                          ***;
********************************************************************************;

data exampledata0;
  call streaminit(123);
  do SUBJID=1 to 500;
    EVENTTIME=rand("EXPONENTIAL");
    RANDTREAT=rand("BERNOUILLI", 0.5);
    CATEGORY=rand("BINOMIAL", 0.2, 2);
    CONTINUOUS=rand("UNIFORM", 0, 10);
    STOPSTUDY=min(rand("EXPONENTIAL"), 1);
    STOPTREAT=min(rand("EXPONENTIAL"), STOPSTUDY);
    PERIOD=1;
    START=0;
    STOP=min(EVENTTIME, STOPTREAT);
    CNSR=1-(STOP=EVENTTIME);
    IMPTREAT1=RANDTREAT;
    IMPTREAT2=RANDTREAT;
    output;
    PERIOD=2;
    START=min(EVENTTIME, STOPTREAT);
    STOP=min(EVENTTIME, STOPSTUDY);
    CNSR=1-(STOP=EVENTTIME);
    IMPTREAT1=99;
    IMPTREAT2=RANDTREAT;
    output;
  end;
run;

proc sql;
  create table exampledata1 as select *, (STOPSTUDY<1 and sum(CNSR=0)<1) as FLAG
    from exampledata0
    group by SUBJID
    order by SUBJID, PERIOD;
quit;

*Single post-treatment regimen imputation;
%cox_posttreat(seed         = 123,
               dsin         = exampledata1,
               impModel     = T,
               dsoutLabel   = single,
               nImp         = 100,
               imputeFlag   = FLAG,
               imputeMax    = 1,
               startVar     = START,
               stopVar      = STOP,
               cnsrVar      = CNSR,
               periodVar    = PERIOD,
               patID        = SUBJID,
               ContCov      = CONTINUOUS,
               CatCov       = CATEGORY,
               impTreatCov  = IMPTREAT1,
               randTreatCov = RANDTREAT,
               tiesimpute   = efron,
               tiesanalysis = efron);

*shift post-treatment imputation;
%cox_posttreat(seed         = 123,
               dsin         = exampledata1,
               impModel     = TP,
               dsoutLabel   = shift,
               nImp         = 100,
               imputeFlag   = FLAG,
               imputeMax    = 1,
               startVar     = START,
               stopVar      = STOP,
               cnsrVar      = CNSR,
               periodVar    = PERIOD,
               patID        = SUBJID,
               ContCov      = CONTINUOUS,
               CatCov       = CATEGORY,
               impTreatCov  = IMPTREAT2,
               randTreatCov = RANDTREAT,
               tiesimpute   = efron,
               tiesanalysis = efron);

*separate post-treatment regimen imputation;
%cox_posttreat(seed         = 123,
               dsin         = exampledata1,
               impModel     = TbyP,
               dsoutLabel   = separate,
               nImp         = 100,
               imputeFlag   = FLAG,
               imputeMax    = 1,
               startVar     = START,
               stopVar      = STOP,
               cnsrVar      = CNSR,
               periodVar    = PERIOD,
               patID        = SUBJID,
               ContCov      = CONTINUOUS,
               CatCov       = CATEGORY,
               impTreatCov  = IMPTREAT2,
               randTreatCov = RANDTREAT,
               tiesimpute   = efron,
               tiesanalysis = efron);
