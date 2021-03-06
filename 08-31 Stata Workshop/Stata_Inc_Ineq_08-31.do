// do files are the Stata equivalent of .R files. SAVE THEM FREQUENTLY.
// if Stata crashes with a do file open, you WILL lose all your unsaved
// progress (yes, this happened to me when putting this together).

// comments in Stata files begin with two forward slashes, or
* with an asterisk.

/* you can use one forward slash and one asterisk to create a multi-line
comment, meaning that everything is a comment...
for as many lines as you need...
until you're sick of writing comments...
at which point you can end your comment block like this: */

/* Stata syntax can be quite self-explanatory. most commands are given in the
format "command variable, options". to start, let's open a data file, with the
command "use": */
use "/Users/ricardo/Downloads/Latinobarometro/Lat2011Eng.dta"

/* you can get a summary of the data with describe or summarize (note how they
give you different kinds of information!): */
describe
summarize

/* you can also describe (or summarize) specific variables, or groups of 
variables: */
describe idenpa
summarize idenpa tamciud dura

/* note that *many* Stata commands can be abbreviated. for example, there's
d for describe and su for summarize:*/
d idenpa tamciud dura
su idenpa

/* however, when you're starting to learn Stata, I recommend using the "full"
name of commands (with a few exceptions!), because these can get confusing. 
for example, in a month, will you remember if "su" is "summarize" or "sum"? */

/* here's one that you can safely abbreviate, because it's easy to remember
and hard to confuse: generate, or gen, creates a variable. for example, since
this is a survey about political participation, I want to create a variable 
"minor" for respondents below 18. */
gen minor = edad < 18

// how many respondents are below 18? we get a mean of 0.06 -- 6% are minors.
mean minor

/* gen understands quite complex commands. for example: in Brazil, voting is
mandatory for all eligible citizens between ages 18 and 70. it is optional for
those aged 16 or 17, or above 70. I want an "opt_voter" variable that flags
those respondents. */

/* by the way: a period is Stata-speak for a missing value. that "edad < ." is
a way for Stata to NOT include missing values for age in our opt_voter variable.
without that condition, a missing value for age will count in our condition,
because missing values in Stata are coded as very large numbers (like 9999) and 
there is no upper boundary for our "edad > 70" condition. 

any time you "gen" a variable with an inequality condition, you HAVE to consider
the possibility that a missing value will mess you up, and adjust your code
accordingly. */
gen opt_voter = (edad < 18 | edad > 70) & idenpa == "Brazil" & edad < .

/* hmm... this doesn't work! what the heck is a "type mismatch"?
the values of the idenpa variable are *not* the names of countries! those are
labels for the variable, whose actual values are numeric codes. you can find
the list of labels + values with label list: */
label list IDENPA

* from there, we can actually create the variable in a way that works.
gen opt_voter = (edad < 18 | edad > 70) & idenpa == 72 & edad <.

/* uh-oh, I made a horrible mistake! Brazil is 76, not 72! no problem, we can
just re-do the "gen", right? */
gen opt_voter = (edad < 18 | edad > 70) & idenpa == 76 & edad <.

/* wrong! "opt_voter already defined" suggests to us that we can't replace a
variable with gen. so how could we replace opt_voter? how about "replace"? */
replace opt_voter = (edad < 18 | edad > 70) & idenpa == 76 & edad <.

* equivalently, you can use "if" before our "idenpa == 76" statement:
replace opt_voter = (edad < 18 | edad > 70) if idenpa == 76 & edad <.

/* alongside gen, you will also use gen's overachieving sibling, "egen", which
stands for "gen with extensions" or something like that (different Stata 
references give different versions of that same thing). these extensions are
mostly functions that calculate summaries of data. for example, if I want to
create a variable "mean_age" that equals the mean respondent age in each
country in the survey: */
egen mean_age = mean(edad), by(idenpa)

/* and then I also want a median age function, which I can accomplish in two
ways. between the two, I use "drop" to remove the first median_age variable,
so Stata doesn't bother me about the variable already existing: */
egen median_age = median(edad), by(idenpa)
drop median_age
bysort idenpa: egen median_age = pctile(edad), p(50)

/* note that in the second command below, I use "by" (to group by country)
before the command -- this is allowed in Stata but it won't work unless your
data is *sorted* by the variable that you're grouping by. this is why you should
always use the "bysort" command, as it will sort your data before grouping. 
also note how flexible pctile() is, compared to median()! */

/* just for the sake of completion, we can also create a skew_age variable,
whose values are the mean minus the median respondent age for each country. we
can visualize this variable with "hist" -- it tells us that the age variable is,
for every country, right-skewed -- but the amount of skew varies quite a bit. 
note that I'm using gen instead of egen here. egen works with *functions*. 
you can't use egen to subtract one variable from another.*/
gen skew_age = mean_age - median_age
histogram skew_age

/////////////////

/* Stata can very, very simply give us all sorts of cool descriptive stats. 
for example, I want to know if there are any variables that significantly 
determine the duration of the interviews. that's "dura": */
summarize dura

* we can plot interview duration:
histogram dura, frequency
kdensity dura

/* "over" creates categories. it allows us to build bivariate plots with
categorical variables: (the command here is "graph dot", not "graph" with 
the variable "dot") */
graph dot dura, over(idenpa)

/* similarly, here's a boxplot, which shows us the crazy amount of outliers in
almost every country: */
graph hbox dura, over(idenpa)

/* what's the difference between "over" and "by"? it sounds like they do the 
same thing, but they definitely don't. "over" is for telling your command
that a certain variable represents categories in your data; "by" is for running
the same command several times, once for each value of the variable. 
they behave very differently: */
graph dot dura, over(idenpa)
graph dot dura, by(idenpa)

* but they can be combined:
graph dot dura, over(idenpa) by(sexo)

/////////////////

/* we can build a correlation matrix quite easily, too 
(S34 = socioeconomic level) */
correlate dura edad sexo S34

/* we can also run a regression model with these variables. the outcome (dura)
is specified first, and then all of the explanatory variables. */
regress dura edad sexo S34

/* S34 is a categorical variable, though -- socioeconomic level goes from
"very bad" to "very good": */
label list S34

/* but when we specified the model, Stata treated the S34 variable as a
continuous variable whose values just happen to be all integers and all 
1 through 5. we need to tell Stata that the variable is categorical with "i." */
regress dura edad sexo i.S34

/* by extending the model, we find (in a very non-rigorous kind of way!!) that
interview duration is determined largely by country effects. */
regress dura edad sexo i.S34 i.idenpa

/////////////////

/* now, I'd like to continue working with Latinobarometro data as I know it
decently well, but I have example datasets that I want to move to, so I can
demonstrate some other things. */
use "~/Downloads/daus3/data1.dta"

/* oh no, another error! our error code this time says that data in memory will
be lost. Stata won't load the new dataset unless we explicitly tell it that 
we're okay with loading over the data currently loaded. IF YOU DON'T SAVE
YOUR DATA, YOUR CHANGES WILL BE LOST! let's save the modified dataset first: */
save "LatBar2011.dta"

/* by the way, if the file already exists, you need to tell Stata that you want
to overwrite it: */
save "LatBar2011.dta", replace

* finally, we can open the dataset we want and clear the memory.
use "~/Downloads/daus3/data1.dta", clear

/////////////////

/* this is a 1997 survey with 5,411 German respondents. we'll use it to talk
about the three 'types' of weights that you will use frequently in Stata (this 
section borrows heavily from Kohler & Kreuter's "Data Analysis Using Stata") */
describe

* let's find the mean birth year in the data:
summarize ybirth

/* now, let's save this data for later with the preserve command, which stores
the dataset in a temp directory so that you can easily access it later (with the
"restore" command): */
preserve

* and we'll load a dataset with the birth year data in aggregated form:
use "~/Downloads/daus3/freqwe.dta", clear

/* this new data has two variables: year of birth and "n", which corresponds to
how many respondents in the actual survey data were born in a given year. we can
open the data browser with the browse command: */
browse

/* what is the mean of ybirth here? turns out it's the arithmetic mean of the
numbers 1909 and 1912 through 1992. in other words, Stata has no way of knowing
that we have group-level data. */
summarize ybirth

/* thus, we have our first kind of weighting: *frequency weights*. they are
useful for group-level data, where one row corresponds to a count, rather than 
one observation (e.g., one person, one country, one town) in the data. frequency
weights in Stata are denoted w/ the "fweight" option. the command below gives
the exact same result as the statistics we calculated with the individual-level 
survey dataset! */
summarize ybirth [fweight = n]

* let's check out a different kind of weights with the "analytic weights" data:
use "~/Downloads/daus3/analwe.dta", clear

* the data here looks different:
browse

/* here, each state is... a state. ybirth is the *mean year of birth* in that
state, and n is the number of respondents in that state. in this case, analytic
weights are appropriate. analytic weights are used whenever an observation in
the data is itself a mean, computed from a sample of size n. in this case, n is
the weight variable. analytic weights in Stata are given by "aweight". */
summarize ybirth [aweight = n]

/* the third kind is probability weighting. let's restore our original survey
data: */
restore

/* when you calculate the mean of ybirth in this dataset, you assume that
the sample was obtained by simple random sampling, meaning that every person
had the same probability of being picked for the sample. this assumption is
very rarely met -- real-life samples are almost never drawn from perfect simple
random sampling processes. probability weights help us correct that. 
a probability weight is the inverse of the sampling probability.

for example, picture a survey that includes urban and rural respondents. if I
interview 1/2 of the rural population for my survey but only 1/10 of the urban
population, then: 1) respondents clearly had different probabilities of being
sampled; 2) each rural respondent "represents" 2 people in the rural population,
and each urban respondent "represents" 10 people in the urban population;
therefore 3) our probability weights will be 2 for rural respondents and 10 for
urban respondents. 

probability weights are given by pweight: */
mean ybirth [pweight = xweights]

* note, by the way, that "summarize" doesn't take pweights: 
summarize ybirth [pweight = xweights]

/* that seems frustrating, but it makes total sense: summarize gives you a 
summary of your sample, and nothing else. the "mean" command, however, gives you
an estimate of the population mean (note the confidence interval). it only makes
sense to utilize probability weights when you are using the data to make some 
kind of inference about the population, and not simply describing the sample. */

/* Stata makes it very easy to use weights wherever you may need to, 
which is one of Stata's major selling points. */
regress yedu i.sex i.state i.mar hhsize0to14 [pweight = xweights]

/////////////////

/* Stata supports something it calls 'macros', which are actually strings of
characters that it stores in memory for repeated use (unlike Excel 'macros', 
which are more like scripts)

the syntax is very simple: to create a local macro, you start with the command
'local', then the name you want to give your string, and then the string itself.
for example, say I want to create a series of regression models using the same
explanatory variables. I can do it with a macro: */
local vars yedu ybirth income

/* and then I can run the models, making reference to `vars' (of course, these
models don't make sense theoretically -- just note the syntax!) */
regress hhsize `vars' [pweight = xweights]
regress hhsize0to14 `vars' [pweight = xweights]
regress mar `vars' [pweight = xweights]

/* this is like... half-right, isn't it? we have the "pweight" part repeating
after each model. you can also include that in the macro! macros are *usually*
lists of variables, as that's where you'll save the most typing. but they do NOT
have to be just a list of variables: */
local vars2 yedu ybirth income [pweight = xweights]

* we can build those models again and check that they are the same as before:
regress hhsize `vars2'
regress hhsize0to14 `vars2'
regress mar `vars2'

/* in addition to local macros, you can create global macros simply by replacing
the word "local" with "global". local macros are automatically deleted by Stata
when the .do file or program finishes running; global macros are deleted only
when you exit Stata. local macros are highly recommended. creating global macros
will mess up your work if you run more than one .do file (or work with more than
one dataset) in the same Stata session. */

/////////////////

/* macros are very powerful when combined with loops -- let's create a local
macro of categorical variables to examine the anatomy of a *foreach* loop. */

local categ mar sex emp

* the first line declares the "foreach" command, calls our ad hoc variable 
* "var", and tells Stata what variable list we'll be looping over (in this case, 
* each of the items in "categ")
foreach var in `categ' {
	* inside the curly brackets goes the code that repeats each time the loop
	* runs. in this case, we're simply making tables of self-rated health status
	* vs. each of the variables in "categ"
	tabulate `var' heval
* Stata needs the closing curly bracket to go in its own line
}

/////////////////

/* in this class, you'll be using LIS data frequently -- let's open one of their
sample datasets and work on stuff that will be useful for the LIS self-teaching
homeworks. */

* first, let's open the US 2004 household survey:
use "~/Downloads/us04ih.dta", clear

/* the first thing you'll notice is that the survey has a ginormous number of
variables. Stata does *not* require that we open all of them! if you know you're
only working with a subset of the data, you may specify that subset: */
use hid dhi factor hitsi hitsa hitp hxit hpopwgt nhhmem grossnet using ///
"~/Downloads/us04ih.dta", clear

/* the first important thing: summarize takes the "de" option to show
descriptive statistics. note the difference: */
summarize dhi
summarize dhi, de

/* the second important thing: Stata saves the results of its general commands,
which you can use later with the r() command. let's see what "summarize, de"
stores: */
return list

/* we can use any of those whenever necessary. for example, let's create a
variable, which I'll call "prophi" that shows each household's income as a
proportion of the 99th percentile: */
gen prophi = dhi/r(p99)

/* sometimes you'll want to use r() but not want your Results tab to be full of
other info that you don't need. the quietly command stores everything in r()
without displaying any of it: */
quietly summarize nhhmem, de

* we can check that the results have been stored in memory:
return list

/* there's also "ereturn", which allows you to retrieve results of *estimation*
commands (statistical models). to demonstrate, let's run a regression model: */
regress hitsi dhi nhhmem

* what's stored in "return"?
return list

* but in ereturn...
ereturn list

* as the output of "ereturn list" shows, we retrieve those objects with e():
display e(r2_a)

/////////////////

/* the LIS website has a sample individual-level dataset of the US in 2004 
as well as the household-level data set we have loaded. we can merge them with
the merge command. in this case, we're doing a one-to-many merge (one household, 
many individuals), & our merge variable is hid, the unique household id. so: */
merge 1:m hid using "~/Downloads/us04ip.dta", keepusing(hid dname pwgt ///
ppopwgt relation partner children age sex ///
immigr educ educ_c emp status1 ptime gross1)

browse

/* note, by the way, that we can specify which variables to load from this "new"
dataset with the keepusing(var1, var2, var3) option. 

merges can be 1:1, 1:m, m:1, and m:m. in this syntax, the "master" dataset 
(which is Stata-merge-talk for the data that's already loaded) goes first. */

/////////////////

/* Stata also supports "programs", which are similar to R functions: chunks of
code that you *define* once and then call by name to execute. in the spirit of
Stata's commonsensical English-language syntax, program definitions begin with 
"program define" and end with "end".

for example, let's use the US04 and the IT04 datasets available on the LIS
website to solve Problems 1 and 2 of Part 2 in LIS's self-teaching package. 
they ask us to: 

1) create a combined data file for both countries that contains both individual
and household-level data;
2) find the percentage of people aged 25-54 who are homeowners;
3) find, among women aged 25-54 who are either the household head or the spouse
of the household head, what percentage are employed;
4) find, among employed women with the same characteristics as 3, what 
percentage have part-time employment.

to do that, we can first create a small program that merges household-level & 
individual-level data, appends one to the other, and saves them to a file. 
we can start by creating global macros to store 1) the dataset file names; 
2) the variables for individual-level datasets that we want to use; 3) the 
variables we want to use for hh-level datasets. */ 

global datasets "us04i it04i"
global varspp "hid dname age pwgt sex ppopwgt relation emp ptime"
global varshh "hid own"

/* this "capture program drop" is in case a program with the same name is 
already defined.*/
capture program drop merge_data

/* this defines the program merge_data; note how you "call" global macros with
dollar signs rather than quotation marks. can you go through the program, line
by line, and explain to yourself what it does? */
program define merge_data
	foreach dataset in $datasets {
		use $varspp using `dataset'p, clear
		merge m:1 hid using `dataset'h, keepusing($varshh)
		keep if inrange(age, 25, 54) & relation <= 2200
		if "`dataset'" != "us04i"{
			append using exercise2_rgg
		}
	save exercise2_rgg, replace
	}
end

* here, we execute the program we just created and then load the data it saved:
merge_data

use exercise2_rgg, clear

recode own (100/199=1) (200/299=0), gen(homeowner)

bysort dname: summarize homeowner [aw=ppopwgt]
bysort dname: tabulate sex emp [aw=ppopwgt], row
bysort dname: tabulate sex ptime [aw=ppopwgt] if emp==1, row

/////////////////

/* I'm a firm believer in learning by tinkering, fixing things by trial and
error, googling error codes and reading the StackExchange explanations carefully
(instead of _only_ copy-pasting the correct code), etc. that's how I've learned
almost everything I know about coding. but there are also several great, free
online resources at your disposal. my three favorites are:

- a collection of cheat sheets:
https://geocenter.github.io/StataTraining/pdf/AllCheatSheets.pdf

- an online guide with quick introductions to most of Stata's functionality: 
http://wlm.userweb.mwn.de/Stata/

- a huge list with awesome resources on every aspect of Stata you will ever 
need to learn: https://sites.google.com/site/mkudamatsu/stata 

also: ask for help! I have weekly office hours and I'm available by appointment
and over e-mail. it's my job to answer questions and help you figure things out!
don't hesitate to ask a question if it comes up. I'm not an expert Stata user,
but I'm a very experienced tinkerer and googler of error codes! */
