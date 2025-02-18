*First dataset=Initial study;
 
/*Reading the dataset in SAS*/
Filename F1 "C:\Users\jn746\OneDrive - Rutgers University\SAS\project\Initial study_project.txt";
data initial_study;
infile F1 dsd missover;
input Patient_ID$ Age State$ Length_of_Stay Total_Charge;
run;
proc print data=initial_study;
run;


/*Descriptive Statistics to check the data*/
proc means data=initial_study N min max;
run;

proc freq data=initial_study;
run;

proc univariate data=initial_study;
run;


/*Cleaning the dataset*/
data initial_study_copy;
set initial_study;
if Patient_ID='' or Age='.' or State='' or Length_of_Stay='.' or Total_Charge='.' then delete;
run;
proc print data=initial_study_copy;
run;

/*Sorting the data*/
proc sort data=initial_study_copy out=initial_study_sort nodupkey;
by Patient_ID;
run;
proc print data=initial_study_sort;
run;


/*Second dataset = second_study*/

/*Reading the dataset in SAS*/
data second_study;
infile"C:\Users\jn746\OneDrive - Rutgers University\SAS\project\second_study project.txt" dsd missover;
input Patient_ID$ Site$ Group$ test_score;
run;
proc print data=second_study;
run;

/*Descriptive Statistics*/
proc freq data=second_study;
run;

proc univariate data=second_study;
run;

/*Cleaning the dataset*/
data second_study_copy;
set second_study;
if Site='N/a' or Group='n/a' then delete;
run;
proc print data=second_study_copy;
run;

/*Sorting the data*/
proc sort data=second_study_copy out=second_study_sort nodupkey;
by Patient_ID;
run;
proc print data=second_study_sort;
run;


libname L1 "C:\Users\jn746\OneDrive - Rutgers University\SAS\project\L1";

/*Merging the files * Horizontal merge*/
data L1.Study_merge;
merge initial_study_sort(in=a) second_study_sort(in=b);
by Patient_ID;
if a=1 and b=1;
run;
proc print data=L1.Study_merge;
run;


/*Simple Random Sampling*/
proc surveyselect data=L1.Study_merge method=srs seed=6 sampsize=1000 out=L1.sample_study;
id _all_;
run;
proc print data=L1.sample_study;
run;

proc contents data=L1.sample_study;
run;


/*Conditional Processing*/
data L1.sample_copy (rename=(Site=CT_Location test_score=FBS_level));
set L1.sample_study;
run;
proc print data=L1.sample_copy;
run;

data L1.Sample_final;
set L1.sample_copy;
if Age<=15 then Age_group="Children";
else if Age>=16 and Age<=30 then Age_group="Youngadults";
else if Age >=31 and Age<=65 then Age_group="Middleage";
else Age_group="Oldage";
if FBS_level<=70 then Diagnosis="Hypoglycemic"; 
else if FBS_level>70 and FBS_level<100 then Diagnosis="Normal";
else if FBS_level>=100 and FBS_level<=125 then Diagnosis="Prediabetic";
else Diagnosis="Diabetic";
run;
proc print data=L1.Sample_final;
run;


/*Descriptive statistics*/
proc freq data=L1.Sample_final order=freq nlevels;
tables State CT_Location Group Age_group Diagnosis/nocum nopercent;
run;

/*Distribution of Data*/ 
proc univariate data=L1.Sample_final;
run;

ods graphics on;

/*Does the mean FBS levels of the population differ from the hypothesized mean*/
/*One-sample t-test*/
proc ttest data=L1.Sample_final
plots(shownull)=interval
H0=100;
var FBS_level;
title "One-sample t-test to test whether mean FBS_level=100"; 
run;


/*Does Drug A result in reduction in FBS levels compared to the placebo*/
/*Conditional Processing*/
data L1.sample_ttest;
set L1.Sample_final;
if Group="Low" then Group="Drug";
if Group="High" then Group="Drug";
run;
proc print data=L1.sample_ttest;
run;

/*Two-sample t-test*/
proc ttest data=L1.Sample_ttest;
class Group;
var FBS_level;
title "Two-Sample t-test comparing FBS_levels, DRUG VS PLACEBO";
run;

/*Is there any difference in FBS levels among age groups with Drug A?
/*One-way ANOVA*/
proc ANOVA data=L1.Sample_final;
class Age_group;
model FBS_level=Age_group;
means Age_group/DUNCAN;
title"One-way ANOVA with Age group as Predictor";
run;
quit;

proc sgplot data=L1.Sample_final;
vbox FBS_level/category=Age_group
connect=mean;
title"Differences in FBS levels across Age groups";
run;


/*Is there any difference in the mean FBS levels among groups across CT locations?
Two-way ANOVA*/
proc GLM data=L1.Sample_final;
class CT_location Group;
model FBS_level=CT_location Group
CT_location*Group;
lsmeans CT_location Group/diff adjust=tukey;
title'Model with Clinical Trial locations and Drug groups as predictors';
run;
quit;

/*Does the interaction between states and Drug groups influence the fasting sugar levels?
Two-way ANOVA*/
proc GLM data=L1.Sample_final plots=intplot;
class State Group;
model FBS_level=State Group
State*Group;
lsmeans State*Group/diff slice=State;
title'Model with States and Drug groups as predictors';
run;
quit;


/*Do the distribution patterns of diagnoses deviate from the 
expected ones,assuming proportions of 15%, 30%, 35%, and 20%*/
proc freq order=data;
weight FBS_level;
title'Goodness of fit Testing';
tables diagnosis/nocum testp=(.15,.3,.35,.2);
run;


/*Does the total charge incurred by patients 
correlate with their test scores?*/
proc corr data=L1.Sample_final;
var FBS_level total_charge;
run;

proc sgscatter data=L1.Sample_final;
plot FBS_level*total_charge/reg;
title'association of hospital charges with test results';
run;


/*Is there any correlation between the length of
stay in the hospital and the sugar levels of patients*/
proc corr data=L1.Sample_final;
var FBS_level Length_of_Stay;
run;

proc sgscatter data=L1.Sample_final;
plot FBS_level*Length_of_Stay/reg;
title'association of length of stay with test results';
run;













