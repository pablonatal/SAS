/*********************************************************************************************************
*   NAME: PlotNumericalVar.sas                                                           
*                                                                                                
*   DESCRIPTION OF THE PROGRAM:                                                       
*                                                                                                
* 		Get statistics and graphics of a numeric variable
* 
*   REVIEWED   : Accenture
*   DATE       : October 2014                                                        
*   AUTHOR     : Pablo Natal
*   VERSION    : Melia - Descriptive Analysis
*********************************************************************************************************
*  INPUT:      
*			@param	table 				Input table
*           @param	var 				Name of categorical variable to analyze
*                                                                          
*  OUTPUT:     
*          	@table	SUMMARY_NUMERICAL	Table containing one row of statistics per variable 
*			@output report				Report containing statistics, boxplot and histogram per variable	
*                                                                          
********************************************************************************************************/



%macro PlotNumericalVar(
 table = ,
 var = 
);
	%PUT NOTE-PlotNumericalVar: INICIO;
	/* 	--------------------------------
		Filter variable of analysis 
		-------------------------------- */
	data work.auxiliar; 
	 set &table. (keep =  &var.);			
	run;

	/* -------------------------------------------------------------------
	   Proc Means
	   ------------------------------------------------------------------- */
   proc means data= work.auxiliar;
        var &var.;
        output out= work.outmeans
			n=Rows nmiss=Miss mean=Avg median=mediana  stddev=desvstd min=Minimo  max=Maximo range=rango
			q1=qu1 q3=qu3 p1=pct01 p5=pct05 p10=pct10 p90=pct90 p95=pct95 p99=pct99 
     run; 
	 
	proc sql;
	create table work.outmeans2 as
		select 	"&table." as TABLE length=64,
				"&var." as VARIABLE length=64,
				a.Rows, a.Miss, a.Avg, a.mediana, a.desvstd, a.Minimo, a.Maximo, a.rango,
				a.qu1, a.qu3, qu3-qu1 as rangoQs, a.pct01, a.pct05, a.pct10, a.pct90, a.pct95, a.pct99					
		from work.outmeans a;
	quit;




	/* -------------------------------------------------------------------
	   OUTLIERS
	
PROC SQL;
			CREATE TABLE TMP_SUMMARY_STATISTICS
			AS SELECT 	&OBS_DATE. AS OBS_DATE,
						COUNT(CLNOCL) AS POPULATION,
						SUM(TARGET1_2M_1500) AS NB_TARGET1_2M_1500,
						100*(CALCULATED NB_TARGET1_2M_1500 / CALCULATED POPULATION) AS PCT_TARGET1_2M_1500,

	proc sql noprint; 	
	 select max(&var.)	as maximo,
			min(&var.)	as minimo,
			count(1)	into :num_miss 
		from work.auxiliar where &var. = .;
	quit;
   ------------------------------------------------------------------- */

	/* Load macrovars */
	data _null_; 
	 set work.outmeans2 end=last; 
		call symput("myminimo", put(Minimo,best32.));
		call symput("mymaximo", put(Maximo,best32.));
		call symput("myqu1", put(Qu1,best32.));
		call symput("myqu3", put(Qu3,best32.));
	run;

	%put myminimo=&myminimo. mymaximo=&mymaximo. myqu1=&myqu1. myqu3=&myqu3.;

	/* Calculate new columns for outliers */
	data work.auxiliar; 
	 set work.auxiliar;
		format maximo minimo qu1 qu3 best32.;
		maximo = &mymaximo.;
		minimo = &myminimo. ;
		qu1 = &myqu1.;
		qu3 = &myqu3.;
		if (&var. lt (qu1-1.5*(qu3-qu1)) or &var. gt (qu3+1.5*(qu3-qu1))) then outlier = 1;
		else outlier=0;
	run;

	/* Get total of outliers */
	proc sql noprint; 	select sum(outlier) into :myoutliers from work.auxiliar;	quit;

	/* Load */
	data work.outmeans2; 
	 set work.outmeans2; 
	 format outliers best32.;
		outliers = &myoutliers.;
	run;
	

	/* Append results to keep track of all the variables from the table */
	proc append base = &outname._NUM
				data = work.outmeans2 force;
	run;


	%goto SALIDA;



	/* -------------------------------------------------------------------
	   Generate a summary table
	   ------------------------------------------------------------------- */

	proc sql noprint; 	select max(&var.) into :maximo from work.auxiliar;	quit;
	proc sql noprint;	select min(&var.) into :minimo from work.auxiliar;	quit;
	proc sql noprint; 	select count(1) into :num_miss from work.auxiliar where &var. = .;	quit;

	%let dif = %eval(&maximo.-&minimo.);
	%let step = %eval(&dif./100);
	%put &maximo. &minimo. &dif. &step.;

	%do i = 1 %to 100;
		%let inicio  = %eval(&step.*&i.);
		%let minimo_&i. = %eval (&inicio.+&minimo.-&step);
		%let maximo_&i. = %eval (&inicio.+&minimo.);
	%end; 

	data work.auxiliar;
	 set work.auxiliar;
	 	format percentil min_value max_value best32.;
			%do i = 1 %to 100;
				%let truemin =  %eval(&var. > &&minimo_&i..);
				%let truemax =  %eval(&var. < &&maximo_&i..);
				%put &truemin. and &truemax.;
				%if &i. < 100 %then %do; 
					if (&var. >= &&minimo_&i..) and (&var. < &&maximo_&i..) then do;
						percentil = &i.; 
						min_value =  &&minimo_&i..; 
						max_value =  &&maximo_&i..; 
					end;
				%end;
				%if &i. = 100 %then %do; 
					if (&var. >= &&minimo_&i..) /*and (&var. <= &&maximo_&i..)*/ then do;
						percentil = &i.; 
						min_value =  &&minimo_&i..; 
						max_value =  &&maximo_&i..; 
					end;
				%end;
			%end;
	run;

	/* Get frequencies of all data by percentiles */
	PROC FREQ DATA=work.auxiliar ORDER=INTERNAL;
		TABLES percentil / MISSPRINT MISSING  SCORES=TABLE plots(only)=freq OUT=WORK.tmp_salidafreq;
	RUN;

	/* Add min and max values of each percentile */
	proc sort data=work.auxiliar out=work.auxiliar_sorted nodupkey;
	by percentil; run;

	proc sql;
	 create table work.summary as
		select "&table." as table,
				"&var." as variable,	
				a.*,
				b.min_value,
				b.max_value
			from work.tmp_salidafreq a
			LEFT OUTER JOIN work.auxiliar_sorted b
			 on a.percentil = b.percentil;
	quit;


	proc append base = &table._NUM_PCT
				data = work.summary force;
	run;


	/* -------------------------------------------------------------------
	   BOX PLOT
	   ------------------------------------------------------------------- 
	proc boxplot data=WORK._TMP_;
		plot ( &var. ) * DUMMY 
		/ 
			CAXES=BLACK
			CFRAME=GRAY
			ctext=BLACK 
			cboxes=BLACK 
			cboxfill=BLUE
			idcolor=BLUE
			boxstyle=schematicid
			WAXIS=1
			haxis=axis1;
	run;

	axis1;*/

	/* Delete unnecessary tables */
	proc datasets lib=work nolist;
			delete _TMP_ /memtype=view; 
		symbol; 
		GOPTIONS ftext= ctext= htext=; 
	RUN; QUIT;

	TITLE; FOOTNOTE;
	/* -------------------------------------------------------------------
	   Restoring original device type setting.
	   ------------------------------------------------------------------- */
	OPTIONS DEV=ACTIVEX;


	/* -------------------------------------------------------------------
	   APPEND to have all parameters of the variables in one table
	   ------------------------------------------------------------------- *

		data work.univariateOut;
		 set work.univariateOut;
		 format TABLE VARIABLE $32. n mean std var min max best32.;
		 TABLE = "&table.";
		 VARIABLE = "&var.";
		 NUM_MISSING = &num_miss.;
		run;

		proc append base = SUMMARY_NUM
					data = work.univariateOut force;
		run;

		 */

	%SALIDA:

		/* Delete tables */
		proc sql;
			drop table 	work.auxiliar,
						work.summary,
						work.outmeans,
						work.outmeans2,
 						work.tmp_salidafreq,
						work.univariateOut
			;
		quit;
	
	%PUT NOTE-PlotNumericalVar: INICIO;

%mend PlotNumericalVar;

/*

%PlotNumericalVar(
 table = data.Minutos,
 var = VLR_MENSAJES
);
*/
