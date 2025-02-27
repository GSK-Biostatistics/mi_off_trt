/************************************************************************************************************************************
MISTEP macro.
Main release. June 2018.
(See versions section below for updates)

A regression based MI macro;
Written by Professor James Roger (LSHTM);

*************************************************************************************************************************************
** Open Source licence (MIT):                                                                                                       *
** Copyright 2017 James Henry Roger                                                                                                 *
**                                                                                                                                  *
** Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files *
** (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify,     *
** merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is        *
** furnished to do so, subject to the following conditions:                                                                         *
**                                                                                                                                  *
** The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.   *
**                                                                                                                                  *
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES  *
** OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS     *
** BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,          *
** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                          *
*************************************************************************************************************************************


The purpose of this macro is to allow one to impute repeated measures data with monotone missing data 
using the sequential regression approach but, do this either as
1) a CONDITIONAL approach (this is like the MONOTONE REG facility in proc MI)
OR
2) a MARGINAL approach (this allows MNAR approaches such as J2R to be fitted sequentially).


THE CORE IDEA:
The sequential regression approach to imputing monotone missing data in repeated measures Gaussian data works visit by visit,
 regressing the outcome at each visit on the baseline covariates and also the previous observed response values. 
At each stage (visit) parameter estimates for this regression model are sampled from the Bayesian posterior and for each set of
 parameter values a data set is created where the missing values for the response variable are imputed as random draws from
 their implied distribution. It is worth noting at this stage that the algorithm could equally well be implemented by regressing
 at each stage on the residuals from the previous fits, although implementing such an algorithm would be more complex.

This algorithm imputes values under a Missing at Random (MAR) assumption. As such it is similar to much early MI software.
The algorithm is implemented in the MI procedure in SAS using the MONOTONE REEG facility, but the SAS macro described here extends
 what can be done without using proc MI at all.

More recently several suggestions have been made to modify the imputation procdure my imputing subjects as if they belonged to
 different treatment groups. For instance after withdrawal one might impute subjects in the active arm as if they belong to the
 control or placebo arm. If we do this then different things happen depending upon whether we regress on previous observed values 
 or on previous residual values. What is the difference?
1) When we regress on previous observed values the impact of the early observed value on the imputed values is in terms of the
 difference between observed value and the mean for the placebo arm even though the subject was at that time on active.
 This is the result of using the CONDITIONAL model approach.
2) When we regress on previous residual values the impact of the early observed value is in terms of the difference between observed
 value and the mean for the subject's own arm (his residual). This is the result of using the MARGINAL model approach.

While it is easy to do (1) within the MI procedure (see OKelly & Ratitch book Clinical Trials with Missing Data) it is quite
 difficult to implement (2) within proc MI. The purpose of this macro is to make it equally easy to fit such marginal models as (2).


HOW IT WORKS (Conditional):
The macro takes an input data set and adds additonal variables while maintaining the original variables in their orginal state.
While doing this it imputes values to replace missing data in the response variable to create a new IMPUTED variable.
It never alters existing data, even missing data values. All imputation creates new variables.

To implement a simple MAR MI, the first two steps are implemented with macro as follows.
%mistep(In=DS1 ,Out=DS2 ,Response=Change4 ,Class=Therapy ,Model=Therapy Basval , Nimpute=50 ,seed=12345);
%mistep(In=DS2 ,Out=DS3 ,Response=Change5 ,Class=Therapy ,Model=Imputed1 Therapy Basval ,seed=12321);

If, as here, we have no imtermediate missing data then we start out with a dataset DS1 which has a complete set of the data
 in parallel mode (one record per subject).

In the first macro call the outcome at the first visit (variable Change4) is regressed on Treatment (Therapy) and on baseline (Basval).
Missing values for Change4 are imputed and a new variable IMPUTED1 created in the new data set DS2. This is done 50 times (NIMPUTE=),
 and each imputed subset of the data is indexed by the new variable _IMPUTATION_ just as in proc MI.
[The suffix 1 for variable IMMPUTED1 defaults to 1 here, but can be specified by the Suffix= parameter.]

In the second macro call we use the output data set from the first call as input. We do the same to the outcome at the second visit
 (Change5) but here we also include IMPUTED1 in the regression model and generate IMPUTED2 in the data set DS3. 
In the examples below this is repeated for Change 6 and Change7 to generate the imputed data at final visit in variable IMPUTED4,
 ready for analysis and subsequent summary using either the MIANALYZE procedure or the macro %MIANALYZE.
Note how in the second call we do not set NIMPUTE= as the data set already include the variable _IMPUTATION_, and only one new record
 is generated for each existing record.

If the original data have intermediate missing data which we can treated as MAR then we can impute these intermediate missing data before
 using this macro.
Often this original data set will be created by using the MI procedure with the MCMC statement using the MONOTONE option to impute
 intermediate missing data and generate a data set with only monotone missing data.
Alternatively one could impute under MAR using the %mymcmc macro and discard the trailing impted values.

This code allows one to fit standard MAR MI using the sequential regression approach. But the main purpose for developing the macro is
 to fit marginal models such as J2R. 


THE EXTRA BITS (Marginal):
As well as generating the variable IMPUTED1 the macro also generates two other variables MU1 and RESIDUAL1, the mean and the residual
 in exactly the same way. So by replacing IMPUTED1 by RESIDUALl in the MODEL paramter of the second macro call we implement a Marginal
 sequential regression rather than a conditional one. 
%mistep(In=DS1 ,Out=DS2 ,Response=Change4 ,Class=Therapy ,Model=Therapy Basval, NImpute=50, seed=12345);
%mistep(In=DS2 ,Out=DS3 ,Response=Change5 ,Class=Therapy ,Model=Residual1 Therapy Basval, seed=12321);

This approach is implemented in the examples below and we see it gives the same answer. It is only as we move to MNAR models where
the marginal and conditional approaches diverge.


FITTING MNAR-like MODELS
One way to diverge from MAR is to impute after withdrawal as if the subject switches from active to placebo. In line with the
 convention used in the GSK 5 macros,in these examples the conditional version is called "Copy reference" (CR),
 while marginal verion is called "Jump to Reference" (J2R).
Both can be implemented very easily with this macro. First we create a new treatment variable associated with each visit,
 that indicates which treatment the subject is on. Those who withdraw are assumed to switch to a reference treatment after their 
 last visit with a valid response value.
 See the example below where the following SAS code is used to generate a series of treatment variables trt4 to trt7.

data DS1extended;
set DS1;
if change4 < .z then trt4="PLACEBO"; else trt4=therapy;
if change5 < .z then trt5="PLACEBO"; else trt5=therapy;
if change6 < .z then trt6="PLACEBO"; else trt6=therapy;
if change7 < .z then trt7="PLACEBO"; else trt7=therapy;
run;

Then rather than use the treatment variable therapy in each call to the macro we use the new one that is matched to the response
 variable and the visit which is being processed.
In the code below TRT5 is used both in the CLASS parameter and the MODEL parameter.
%mistep(In=DS2 ,Out=DS3 ,Response=Change5 ,Class=TRT5 ,Model=Imputed1 TRT5 Basval, seed=1271);

This implemets the CR approach which is the method used extensively in the OKelly and Ratitch book.

For the marginal approach J2R we use instead
%mistep(In=p2 ,Out=p3 ,Response=change5 ,Class=TRT5 ,Model=Residua11 TRT5 basval ,  Suffix=2 ,seed=1271);


FITTING POST-WITHDRAWAL DATA (Treatment switching)
In a growing number of situations, post-withdrawal of randomized treatment, primary data continue to be collected. However some subjects
   will sometimes go on to withdraw completley from the study. So this post-randomized treatment withdrawal data will be incomplete
   and require imputation.
Models where subjects switch from On-Active to Off-Active, and On-Placebo to Off-Placebo, need to be fitted as marginal models. 
This is easy to do by regressing on the previous residuals.
Code similar to that for J2R can be used with observed values available rather than missing values after randomized treatment withdrawal.


THE EXTRA BITS (DELTA=):
It has become customary to add specific amounts to the mean response after withdrawal in a series of methods known as DELTA adjustment.
Also by varying delta and seeing the impact on the estimated treatment difference, usually at final visit, sensitivity analysis
can be carried out, often known as "stress testing" or "tipping point analysis".
First the delta can be applied to marginal means or to the means in the sequential regression (marginal or conditional).
Second a series of different ways can be used for defining the delta value in terms of
a) the imputation visit. When the delta is applied.
b) the withdrawal visit.
b) length of period between withdrawal and the imputation visit. The value may depend on the lag since withdrawal.
c) perhaps the treatment group to which originally allocated. 

At each visit (call to the mistep macro) we set up a variable Delta<n>, say, which conatins the delta value for each withdrawn subject
 at this visit. We then simply set DELTA=Delta<n> as parameter.

Conditional or marginal is chosen by either regressing on previous Imputed<n> or Residual<n>.

 
THE EXTRA BITS(PREDICTED=)
For marginal imputation methods such as Copy Increment from Reference (CIR), we require the mean value for a subject before withdrawal
 as if they were on the reference treatment.
The PREDICTED= facility allows us to get the modelled mean for an individual subject but with altered covariate values. This does not
 alter the fitted model but supplies the counterfactual mean. It does this by replicating each data record, with altered covariate
 values but with a missing value for response (so it does not effect the model). These records are then later removed and the mean
 (predicted) value handed back in the variable PREDICTED<n>.

The covariate values are altered using DATA step statements supplied within %STR( ).
See the CIR example below for an application. Here the treatment variable Trt4 is forced to the reference value "PLACEBO"

%mistep(Data=DS1extended ,Out=DS2 ,Response=Change4 ,Class=Trt4 ,Model=Trt4 Basval,
	PREDICT= %str(trt4="PLACEBO"), seed=1881);


SEPARATE IMPUTATIONS BY TREATMENT
Traditionally MI was done within Treatment group rather than with Treatment included as part of the regression model.
It is easy to implement this approach using the BY= parameter. The previous example becomes,...
%mistep(In=DS1 ,Out=DS2 ,Response=Change4 ,Model= Basval ,BY= Therapy, Nimpute=50 ,seed=12345);
%mistep(In=DS2 ,Out=DS3 ,Response=Change5 ,Class=Therapy ,Model=Imputed1 Basval, BY= Therapy ,seed=12321);

This is equivalent to using separate covariance matrices in the GSK 5 macros.


MISSING VALUES in IMPUTED variable
Sometimes the macro will generate imputed values which are missing values. This is because there is no way to generate a suitable
 model for the mean for this subject. This can happen for the following reasons 
1) One of the covariates has a missing value for this subject.
2) A classification variable in the model has a level for this subject for which the model cannot estimate the parameter.
      Example: In a model where subjects switch to a new off-treatment level after randomized treatment withdrawal, the new parameter
      can only be estimated if at least some subjects have post-randomization withdrawl data observed before they withdraw totally from
      the study.

ASSUMPTIONS ABOUT THE INPUT DATA SET
1) If multiple imputations exist already in the data set then these must be indexed by the variable _IMPUTATION_ as in proc MI.


MACRO PARAMETERS
Data=       Input data set. (Required)
Out=        Resulting output data set name. Default rules are as follows:
            If the input data set has a numeric suffix (e.g. DSname24) then output data set name suffix is increased by 1 (DSname25).
            Otherwise output data set name is input data set's name with _Out1 added. 
Response=   Name of the Response variable
Class=      List of any categorical variables in the regression model, just like standard SAS.
Model=      The model for the rgression that is required (standard SAS model formula).
Delta=      An expression (evaluated at subject level) which is added to the mean before imputation.
            [Delta does not impact on the estimation of regression parameters. It only affects the imputation process.]
Predict=    This calculates the mean for this subject under alternative covariate settings. Value is in PREDICT<n>
            Data step code is included in %STR() which modifies the covariate values to the required setting.
               This might be several statements separated by semicolons.
            For instance Predict=%str(Therapy="PLACEBO") allows one to calculate the mean on placebo for a subject
                with data at this visit without modifying the underlying data model.
            [PREDICT= has no impact on parameter estimation. It is equivalent to adding a new record with
               altered covariate values but with response data missing, so as to find the mean MU.]
By=         Separate regression models are used within each BY level, as in classic SAS BY statement.
NImpute=    Number of imputations to do. Default is 1, expecting that the data set includes a variable _IMPUTATION_ which already
               indexes the imputation data sets.
            When NImpute>1 a new _IMPUTATION_ variable is created and the macro will error if this variable exists already.
Suffix=     Suffix to add to MU, IMPUTED and RESIDUAL in the output data set.
               Default is to use 1, or next integer in sequence if dataset includes variable IMPUTED<n>,
                  where n is an integer in range 1 to 99. 
Seed=       Sets the seed for the random number generator for imputation. Default is 0 (different from run to run).
Debug=      0 is default.
            1 then intermediate (working) data sets are not deleted at the end
            2 diagnostics are printed to the log
            3 Output from GLIMMIX is not turned off. 

OTHER OUTPUT
The global macro varable MISTEP_ERR is set at the end of each call as follows,
MISTEP_ERR =0 No problems
           1 Some imputed values are set to missing values
           2 The macro has errored. The output data set should not be trusted.


VERSIONS
* Macro was originally built and distributed 24 March 2012 (comments added / edited 22 April 2014);
* Examples and early documentation were added February 2016

* Major revision May and June 2016 with,...
* NIMPUTE= added and _IMPUTATION_ variable expected if Nimpute=1. This then allows multiple BY variables;
* N= renamed as SUFFIX=;
* Changed In= to Data= in line with SAS conventions;
* Delta= and FixedMean= added;
* PREDICTED= added;
* Debug= option added and default dataset names added;
* Automatic SUFFIX value added;
* Separate seeds for the two random number generators added; 

* A supported version was placed on DIA part of www.missingdata.org.uk in July 2016;

* December 2016 a mistake in the OLMCF example was spotted which made FIXEDMEAN= redundent and removed.
* Also set suffix to 1 if no existing suffices found. 

* MISTEP03: January 2017. Fix problem when NIMPUTE=1. James Roger.

* MISTEP04: MARCH 2017. James Roger.
17 MAR 2017: JHR : Add BY check on merging of design matrix back to data. Added for safety purpose only. Problem never seen. 
17 MAR 2017: JHR : Add Warning message when macro imputes a missing value due to problems with the design
                       (covariates missing value or intrinsic aliasing). 
17 MAR 2017: JHR : Add MISTEP_ERR global macro variable. This is useful when running MISTEP several times within a wrapper macro.
13 APR 2017: JHR : Add code to handle case where REMOVE list is null (MISTEP05.SAS)

21 APR 2017: JHR: Correct the MISTE_ERR value. Delete intermediate data sets as soon as free. (MISTEP06.SAS)
22 APR 2017: JHR: Fix a sort problem with BY. (MISTEP07.SAS)
23 JAN 2018: JHR: Improve diagnostic message with hint [mistep08.sas]
30 JAN 2018: JHR: Correct bug whereby if NIMPUTE>1 then same imputed scale was used for all imputations (impact nminor). [mistep09.sas] 
21 MAR 2018: JHR: Alter diagnostic messages
                  Add an array copy so input to FCMP routine simulate is a temporary array (MISTEP10.sas)
27 MAR 2018: JHR: Add summary of call in the LOG at startup. Helps monitor job when using the wrapper MistepWrap.sas macro.
                  The BY= facility has been re-written to use a outer loop rather than use BY at each of the intermediate steps.
                  While apparently less elegant and perhaps slightly less efficient it allows the models for each BY group
                     to have different numbers of levels for factors. This can be useful with sparse data such as follow-on data.
                  (MIStep11.sas)
14 Jun 2018: JHR: Fix bug inroduced in version 11 whereby the new BY loop uses same seed in each loop.
                     This led to underestimation of SED, while SE of direct means were OK. ONly problem when using BY= (MIStep12.SAS)
*/

*options mprint;

* This fcmp subroutine needs loading for use in the MISTEP macro;
* Build an FCMP subroutine to sample from a multivariate Normal distribution with zero mean;
proc fcmp outlib=work.funcs.trial;
subroutine simulate(a[*,*],b[*]);
	outargs a,b;
	n = dim(a,1);
	array chol[1,1] /nosymbols;
	call dynamic_array(chol,n,n);
	array normal[1] /nosymbols;
	call dynamic_array(normal,n);
	call chol(a,chol);
	do i=1 to n;
		normal[i]=rand('NORMAL');
	end;
	call mult(chol,normal,b);
endsub;
quit;


%macro mistep(Data= ,Out= ,Response= ,Class= ,Model= ,Suffix= ,Delta= ,Predict= ,By=, Nimpute=1, Seed=0, debug=0);
%global MISTEP_ERR;
%let mistep_err=0;
%local errtext1 errtext2 stopflag i txt ;
%let stopflag=0;
%* Trap error if user forces a blank NIMPUTE value and use default;
%if %length(&Nimpute) = 0 %then %let Nimpute=1;

%put ***** Running macro MISTEP *****;
%put MISTEP(;
%put   Data= &data;
%put , Out= &Out;
%put , Response= &Response;
%put , Class= &Class;
%put , Model= &Model;
%put , Suffix= &Suffix;
%put , Delta= &Delta;
%put , Predict= &Predict;
%put , By= &By;
%put , Nimpute= &Nimpute;
%put , Seed= &Seed;
%put , Debug= &Debug;
%put );
%put ***** Starting macro MISTEP *****;

%* This checks if CPMLIB is set to works.func and if not adds it to the list;
%let my_cmplib=%sysfunc(getoption(CMPLIB));
%if %index(&my_cmplib,work.funcs) =0 %then %do;
	%put NOTE: Resetting CPMLIB;
	%put options cmplib=(work.funcs _DISPLAYLOC_ &my_cmplib);
	options cmplib=(work.funcs _DISPLAYLOC_ &my_cmplib);
%end;

%if %length(&Out) = 0 %then %do;
	%let i= %length(&data);
	%do %while((&i > 0) & (%datatyp(%substr(&data,&i))=NUMERIC) );
		%let i=%eval(&i-1);
	%end;
	%if &i = %length(&data) %then %let out=&data._OUT1;
	%else %let out=%substr(&data,1,&i)%eval(%substr(&data,%eval(&i +1))+1);
%end;

data _null_;
* Open the data set to check its contents; 
dsid=open("&Data","i");
if dsid<=0 then do;
	call symput("Stopflag","1");
	call symput("Errtext1","Data set <&Data.> does not exist");
	stop;
end;

if attrn(dsid,"nlobs")=0 then do;;
	call symput("Stopflag","1");
	call symput("Errtext1","No observations found in Data set <&Data.>");
	stop;
end;

vnum=varnum(dsid,"_IMPUTATION_");
if vnum<=0 and &Nimpute <2 then do;
	call symput("Stopflag","1");
	call symput("Errtext1","Only one imputation requested with no _IMPUTATION_ variable in the Data set <&Data.>");
	call symput("Errtext2","Hint: Either set NIMPUTE= greater than 1 or add _IMPUTATION_ variable to the Input data set.");
	rc=close(dsid);
	stop;
end;
if vnum>0 and &Nimpute >1 then do;
	call symput("Stopflag","1");
	call symput("Errtext1","Multiple imputations requested with  an _IMPUTATION_ variable in the Data set <&Data.>");
	call symput("Errtext2","Hint: Either set NIMPUTE=1 (default) or remove _IMPUTATION_ variable from the Input data set.");
	rc=close(dsid);
	stop;
end;

%if %length(&Suffix) = 0 %then %do;
	* Get largest suffix number for IMPUTED in variable names;
	do mysuffix=1 to 99;
		vnum=varnum(dsid,"Imputed"||left(put(mysuffix,best3.)));
		if vnum>0 then do;
			call symput("suffix",left(mysuffix+1));
		end;
	end;
%end;

%if %length(&Suffix) = 0 %then %let Suffix=1;

rc=close(dsid);
run;
%if &Stopflag %then %goto errtrap; 
%if &syserr %then %goto myabort; 

%if &debug >= 2 %then %do;
	%put Suffix=&suffix;
%end;

* Delete intermediate datasets in case left behind from previous run;
proc datasets library=work noprint;
delete mistep_data mistep_X mistep_SolF mistep_CovB 
   mistep_Temp1 mistep_Temp2 mistep_Temp3 mistep_Temp4
   mistep_Temp10 mistep_Temp11 mistep_Temp12 mistep_Temp14 mistep_Temp15 mistep_Temp16;	
delete MIStep_Hold_Imp;
quit;
%if &syserr %then %goto myabort; 

%if %length(&BY) %then %do;
	proc sort data=&data out=Mistep_levels1(keep=&BY )  nodupkey;
	by &BY ;
	run;
	%if &syserr %then %goto myabort; 
	
	Data Mistep_Levels2;
	set Mistep_Levels1 end=Mistep_Myend;
	Mistep_BY=_N_;
	if Mistep_MYend then call symput("Mistep_NBY",_N_);
	run;
	%if &syserr %then %goto myabort; 
	%if &debug %then %put Mistep_BY=&Mistep_By;
	
	proc sort data=&data out=Mistep_input1 ;
	by &BY ;
	run;
	%if &syserr %then %goto myabort; 
	data Mistep_Input2;
	merge Mistep_Input1 Mistep_Levels2;
	by &BY;
	run;
	%if &syserr %then %goto myabort; 
	
	%let Data=Mistep_Input3;
%end;	
%else %let Mistep_NBY=1;

* Start of BY= LOOP;
%do Mistep_iby= 1 %to &Mistep_NBY;

	* Delete data set in case left over from failed run;
	proc datasets library=work noprint nolist;
	delete &out._&MIStep_iby;	
	quit;
	%if &syserr %then %goto myabort; 

	%if %length(&BY) %then %do;
		* Get data for BY= subset;
		Data Mistep_Input3;
		set Mistep_Input2;
		where Mistep_By=&Mistep_iby;
		run;
		%if &syserr %then %goto myabort; 
	%end;

	* Build our own working data set;
	* For PREDICTED= we duplicate the records, to build the required alternative mean without affecting the model;
	data mistep_data;
	set &Data;
	retain MIStep_record 0;
	mistep_record +1;
	mistep_real=1;
	output;
	%if %length(&Predict) %then %do;
		&Response=.r;
		mistep_real=0;
		* This is users code to reset covariates for PREDICT=;
		*****************************************************;
		&Predict ;
		*****************************************************;
		output;
	%end;
	run;
	%if &syserr %then %do;
		%let errtext1=Errror in initial DATA step copying data. Is there an error in your PREDICT= parameter?;
		%let errtext2= This should be legal data step code enclosed in macro function STR(). Multiple statements separated are allowed.;
		%goto errtrap; 
	%end;
	
	proc sort data=MIStep_data;
	by %if &Nimpute=1 %then _IMPUTATION_; mistep_record mistep_real;
	run; 
	
	* Run the regression;
	%if &debug <= 2 %then %do;
		ODS select none;
		ODS RESULTS OFF;
		ods graphics off;
		*option nonotes;
	%end;
	proc glimmix data=MIStep_Data outdesign(X=Col NOVAR)=MIStep_X;
	class &class;
	model &response = &model /S COVB;
	ID MIStep_record;
	by %if &Nimpute=1 %then _IMPUTATION_; ;
	ods output parameterestimates=MIStep_solf covb=MIStep_covb ;
	run;
	%if &syserr %then %goto myabort; 
	ods output clear;
	%if &debug <=2 %then %do;
		ODS select all;
		ods Results on;
		ods graphics on;
		*option notes;
	%end;
	
	* Ignoring the scale parameter send estimated parameters for the first imputation only to temp11 and aliased ones to temp10;
	* This is only used to build text to control aliasing;
	data MIStep_temp10 MIStep_temp11;
	set MIStep_solf;
	
	* We only want a single set;
	if Effect="Scale" then stop;
	
	row=_n_;
	if df=. then output MIStep_temp10;
	else output MIStep_temp11;
	run;
	%if &syserr %then %goto myabort; 
	
	* Save away the scale parameter values in temp12;
	data  MIStep_temp12;
	set MIStep_solf;
	keep %if &Nimpute=1 %then _IMPUTATION_; estimate df;
	where Effect="Scale" ;
	df=2*((Estimate/Stderr)**2);
	run;
	%if &syserr %then %goto myabort; 
	
	* Build list that allow us to remove the alised parameters from the calculation;
	* We need to do this because the Cholesky function in FCMP will not handle singular matrices;
	%let remove= ;
	%let remcol= ;
	%let incol= ;
	proc sql noprint;
	select row into :remove separated by "," from MIStep_temp10;
	%if &sqlrc %then %goto myabort;
	select row into :remcol separated by " col" from MIStep_temp10;
	%if &sqlrc %then %goto myabort;
	select row into :incol separated by " col" from MIStep_temp11;
	%if &sqlrc %then %goto myabort;
	quit;
	%if &syserr %then %goto myabort; 
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint nolist;
		delete mistep_Temp10 ;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	
	* Trim macro parameters and send to log if debugging;
	%let remove=&remove;
	%if &debug >= 2 %then %put Remove=&Remove;
	%let remcol=col&remcol;
	%if &debug >= 2 %then %put Remcol=&Remcol;
	%let incol=col&incol;
	%if &debug >= 2 %then %put incol=&incol;
	
	* Build a copy of data set holding regression parameters removing scale parameter and the aliased ones;
	data MIStep_temp15;
	set MIStep_solf;
	retain row 0;
	if effect = "Scale" then do;
		row=0;
	end;
	else do;
		row=row+1;
		%if %length(&Remove) %then %do;
			if row not in(&remove) then output;
		%end;
		%else %do;
			output;
		%end;
	end;
	run;
	%if &syserr %then %goto myabort; 
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint;
		delete  mistep_SolF ;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	
	* Build a copy of the variance covariance for the regression parameters removing rows and colums for aliased parameters;
	data MIStep_temp14;
	set MIStep_covb;
	%if &remcol ^= col %then %do;
		drop &remcol;
	%end;
	%if %length(&Remove) %then %do;
		if row not in(&remove) then output;
	%end;
	%else %do;
		output;
	%end;
	run;
	%if &syserr %then %goto myabort; 
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint nolist;
		delete mistep_CovB; 
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	
	* Get the number of imputations in the original data set and also the number of non-alaised parameters;
	proc sql noprint;
	select count(*) into :nbeta from MIStep_temp11 ;
	%if &sqlrc %then %goto myabort;
	quit;
	%if &syserr %then %goto myabort; 
	%* Trim and send to log if debugging;
	%let Nbeta=&Nbeta;
	%if &debug >= 2 %then %put Nbeta=&Nbeta;
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint nolist;
		delete  mistep_Temp11 ;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	
	* Place all regression parameters on a single record for each imputation;
	proc transpose data=MIStep_temp15 out=MIStep_temp1(drop= _name_) prefix=beta;
	var estimate;
	by %if &Nimpute=1 %then _IMPUTATION_; ;
	run;
	%if &syserr %then %goto myabort; 
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint nolist;
		delete mistep_Temp15 ;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	* Place all covariances for regression parameters on a single record for each imputation;
	* This needs two calls to proc transpose;
	proc transpose data=MIStep_temp14 out=MIStep_temp2 prefix=temp;
	var &incol;
	by %if &Nimpute=1 %then _IMPUTATION_;  row;
	run;
	%if &syserr %then %goto myabort; 
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint nolist;
		delete  mistep_Temp14 ;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	proc transpose data=MIStep_temp2(drop= _name_) out=MIStep_temp3(drop=_Name_) ;
	var temp1;
	by %if &Nimpute=1 %then _IMPUTATION_; ;
	run;
	%if &syserr %then %goto myabort; 
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint nolist;
		delete mistep_Temp2;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	
	* Now merge all the regression information for each imputation together;
	*   and take NIMPUTE= samples from the Bayesian posterior;
	data MIStep_temp4;
	merge MIStep_temp1 MIStep_temp3 MIStep_temp12;
	by %if &NImpute=1 %then _imputation_; ;
	array beta[1:&Nbeta]beta1-beta&nbeta;
	array covb[1:&Nbeta,1:&Nbeta] col1-col%eval(&Nbeta*&Nbeta);
	
	array sigma[1:&Nbeta,1:&Nbeta] _temporary_;
	array sim[1:&Nbeta] _temporary_;
	
	keep _imputation_ beta1-beta&nbeta my_sd;
		* if seed is 0 then keep as zero. Otherwise add 13*(BI loop counter) to make different between BYs;
	* also to keep this seed distinct from rannor below, we add 2341 there;
	* Multiplying seed by 3 makes it use different sequence to the RANNOR( ) later while maintaining 0 for default;
	call streaminit( (&seed ^=0) * (&seed + 13*&Mistep_iby) ) ;
		
	do i=1 to &Nbeta;
		if beta[i] <= .z then do;
			call symput("Stopflag","1");
			call symput("Errtext1","Element "||put(i,4.0)||" in estimated parameter vector Beta has missing value.");
			call symput("Errtext2","Estimation problem: Do class variables change from imputation to imputation?");
			stop;	
		end;
	end;
	
	%* If we are imputing several records then Nimpute>1 and we create new index _IMPUTATION_;
	%* Need to copy Beta first as we overwrite its values;
	%if &Nimpute>1 %then %do;
		array betacopy[1:&Nbeta] _temporary_;
			do i=1 to &nbeta;
				betacopy[i]=beta[i];
			end;
		do _IMPUTATION_=1 to &Nimpute;
	%end;
	sigma2=df*estimate/rand("CHISQUARE",df);
	my_sd=sqrt(sigma2);
	rescale=sqrt(sigma2/estimate);

	* Copy into temporary array to keep some versions of SAS FCMP/DATA step happy;
	* Not needed in SAS 9.4;
	do i=1 to &nbeta;
		do j=1 to &nbeta;
			sigma[i,j]=covb[i,j];
		end;
	end;

	call simulate(Sigma,sim);
	do i=1 to &nbeta;
		%if &Nimpute>1 %then %do;
			beta[i]=betacopy[i]+sim[i]*rescale;
		%end;
		%else %do;
			beta[i]=beta[i]+sim[i]*rescale;
		%end;
	end;
	output;
	%if &Nimpute>1 %then %do;
		end;
	%end;	
	run;
	%if &Stopflag %then %goto errtrap; 
	%if &syserr %then %goto myabort; 
	
	%if &debug = 0 %then %do;
		proc datasets library=work noprint nolist;
		delete mistep_Temp1 Mistep_Temp3 Mistep_Temp12;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
	* Merge the design matrix onto the original data on a record by record basis;;
	data MIStep_temp16;
	merge MIStep_data MIStep_X%if &Remcol ^= col %then (drop=&remcol); ;
	by mistep_record;
	%if &Nimpute>1 %then %do;
	 do _IMPUTATION_=1 to &Nimpute;
	 	OUTPUT;
	 end;
	%end;
	run;
	%if &syserr %then %goto myabort; 
	
	* Merge the sampled regression coefficients and residual variance with the original data and design matrix;
	proc sort data=MIStep_temp16 ;
	by _IMPUTATION_;
	run;
	%if &syserr %then %goto myabort; 
	
	data &out;
	merge MIStep_temp16 MIStep_temp4 end=mistep_last;
	by _imputation_ ;
	array beta[1:&Nbeta]beta1-beta&nbeta;
	array X[1:&Nbeta] &incol;
	drop mistep_missing i beta1-beta&nbeta &incol my_sd mistep_real
		%if %length(&Predict) %then mistep_check; 
		%if %length(&BY) = 0 %then mistep_record; ;
	retain mistep_missing 0;
	MU&Suffix=0;
	* Calculate the predicted mean;
	do i=1 to &nbeta;
		MU&Suffix=MU&Suffix+beta[i]*x[i];
	end;
	
	if mistep_real=1 and &response < .z  then do;
		* This is for those who need imputation, but is not an extra record for PREDICTED=;
		%if %length(&Delta) %then %do;
			if (&Delta) > .z then MU&Suffix=MU&Suffix + (&Delta);
		%end;
		%* Here we generate a slightly different seed to that above by adding 2341. But still uses 0 if seed is zero;;	
		Imputed&Suffix=MU&Suffix+rannor((&seed ^=0) * (&seed + 13*&Mistep_iby + 2341)) * my_sd;
	end;
	else imputed&Suffix=&response;
	
	residual&Suffix= Imputed&Suffix - MU&Suffix;
	if Imputed&Suffix<=.z 
	    %if %length(&Predict) %then %do;
	    	and mistep_real=1
	    %end;
	then do;
		mistep_missing + 1;
	
	PUT "Mistep_missing= " mistep_missing;	
	PUT "UPDATING MISTEP_MISSING MISTEP_Record= " mistep_record "_imputation_=" _imputation_;
		
		if mistep_missing <=10 then do;
			put "Imputed value is missing for record [ " mistep_record "] _imputation_=" _imputation_; 
		end;
	end;
	%if %length(&Predict) %then %do;
		retain Predict&Suffix mistep_check; 
		if mistep_real=0 then do;
			* Note that DELTA= has no impact when mistep_real=0. This is pure model.;
			Predict&Suffix=MU&Suffix;
			mistep_check=mistep_record;
		end;
		if mistep_real=1 then do;
			if mistep_check = mistep_record then output;
			else do;
				call symput("Stopflag","1");
				call symput("Errtext1","Problem with PREDICT= calculation in macro MISTEP. This should not happen");
				call symput("Errtext2","Please report to James Roger.");
				stop;
			end;
		end;		
	%end;
	%else output;;
	if mistep_last then do;
		if mistep_missing then do;
			put "WARNING:";
			put "WARNING: " mistep_missing " records have had missing values imputed";
			put "WARNING: Possible causes are missing covariate values or factor levels with non-estimable parameters (intrinsic aliasing)";
			put "WARNING: First ten records indicated above";
			put "WARNING:";
			call symput("mistep_err","1");
		end;
	end;
	run;
	%if &Stopflag %then %goto errtrap; 
	%if &syserr %then %do;
		%let errtext1=Unidentifiable error in final data step creating Data set &out;
		%let errtext2=This may be that the parameter string for DELTA= is not a valid SAS numeric expression. Check data types etc.;
		%goto errtrap; 
	%end;
	
		%* There is some inefficiency here in copying results from Base= data set to output but this allows 
	      code with no BY= to flow easily;
	%if %length(&BY) %then %do;
		* Do not need to add in the BY values;
		proc append Base=MIStep_Hold_Imp data=&Out;
		run;
		%if &syserr %then %goto myabort;
		%* Copy back into required data set at the end and sort by _imputation_ and mistep_record;
		%if &MIStep_iby= &MIStep_NBY %then %do;
			proc sort out=&Out(drop=mistep_record) data= MIStep_Hold_Imp;
			by _imputation_ mistep_record;
			run;
			%if &syserr %then %goto myabort; 
		%end;
	%end;

	%if &debug = 0 %then %do;
		proc datasets library=work noprint;
		delete mistep_Temp4 mistep_Temp16;	
		quit;
		%if &syserr %then %goto myabort; 
	%end; 
	
%end;
	
%goto myend;

%myabort:
%let errtext1=Untrapped error [Report to James Roger];

%errtrap:
	%let mistep_err=2;
	* Additional quit and run to flush any existing data step or proc;
	quit; run;
	* Now put error message and stop macro;	
	%PUT %str(ERR)OR: ; 
	%PUT %str(ERR)OR: In macro MIStep; 
	%PUT %str(ERR)OR: &errtext1;
	%PUT %str(ERR)OR: &errtext2;		
	%PUT %str(ERR)OR: ;
%myend:

%mend mistep;

* End of the MISTEP macro code; 
*************************************************************************************************************************************;
