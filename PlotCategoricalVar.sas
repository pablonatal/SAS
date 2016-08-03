/********************************************************************************************
*   NAME: PlotCategoricalVar.sas                                                           
*                                                                                                
*   DESCRIPTION OF THE PROGRAM:                                                       
*                                                                                                
* 		Get statistics and graphics of a categorical variable
* 
*   REVIEWED   : Accenture
*   DATE       : October 2014                                                        
*   AUTHOR     : Pablo Natal
*   VERSION    : Melia - Descriptive Analysis
********************************************************************************************
*  INPUT:      
*                   @param	table 			Input table
*                   @param	var 			Name of categorical variable to analyze
*                   @param	threshold 		Minimum percentage of obs. to consider that value as
*											one category; otherwise it is input as "OTHER" 
*                                                                          
*  OUTPUT:     
*                   @table				
*                                                                          
*******************************************************************************************/



%macro PlotCategoricalVar(
 table = ,
 var = ,
 threshold = 1
);

	%PUT NOTE-PlotCategoricalVar: INICIO;

	/* Filter de variable of analysis */
	data work.auxiliar; 
	 set &table. (keep =  &var.);			
	run;

	/* If we do not want to assign the OTHER category then skip this step */
	%if &threshold. = 0 %then %do;
		%goto SIGUIENTE;
	%end;

	/* Get frequencies */
	PROC FREQ DATA=work.auxiliar ORDER=INTERNAL /*NOPRINT*/ ;
		TABLES &var. / MISSPRINT MISSING  SCORES=TABLE plots(only)=freq OUT=WORK.OneWayFreq
		(LABEL="Cell statistics for &var. analysis of WORK.ORIGEN");
	RUN;

	/* Filter the categories we want to rename based on a threshold of percentage of appearances */
	data work.OneWayFreq; 
	 set work.OneWayFreq;	
	 if PERCENT < &threshold. then output;	
	run;

	/* Load macrovars */
	data _null_; 
	 set work.OneWayFreq end=last; 
		call symput("var"||compress(_n_), compress(&var.));
		if last then call symput("numVars", compress(_n_));
	run;

	/* If there is only one categort to rename, it does not make sense to do the transformation */
	data work.auxiliar; 
	 set work.auxiliar;
	 %if &numVars. > 1 %then %do;
		format 	values $256.;
		if &var. in (	
		 %do i = 1 %to &numVars.;
			%if &i. = 1 %then "&&var&i.." ;
			%else , "&&var&i.." ;
		 %end;
		) then values = "OTHER";
		else  values = &var.;
	 %end;	
	run;

	%SIGUIENTE:

	/* Get the final data*/
	PROC FREQ DATA=work.auxiliar ORDER=INTERNAL;
		TABLES &var. / MISSPRINT MISSING  SCORES=TABLE /*plots(only)=freq*/ OUT=WORK.outfreq;
	RUN;

	/* -------------------------------------------------------------------
	   APPEND table to have all variable summaries in one table
	   ------------------------------------------------------------------- */
	data work.outfreq (drop= &var.);
	 set work.outfreq;
	 format TABLE VARIABLE $64.;
	 TABLE = "&table.";
	 VARIABLE = "&var.";
	 VALUES = input(&var. ,$64.);
	run;
	
	proc append base= &outname._CAT 
				data= work.outfreq force;
	run;

	/* Delete tables */
	proc sql;
		drop table 	work.auxiliar, 
					work.outfreq
		;
	quit;

	%PUT NOTE-PlotCategoricalVar: FIN;

%mend PlotCategoricalVar;



