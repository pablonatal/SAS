/********************************************************************************************
*   NAME: 02_DescriptiveAnalysis.sas                                                           
*                                                                                                
*   DESCRIPTION OF THE PROGRAM:                                                       
*                                                                                                
* 		Analyze all data varaiables of input dataset depending of the type of variables:
*			- numeric
*			- categorical
*			- data
* 
*   REVIEWED   : Accenture
*   DATE       : October 2014                                                        
*   AUTHOR     : Pablo Natal
*   VERSION    : Melia - Descriptive Analysis
********************************************************************************************
*  INPUT:      
*                   @table	mytable 		Table with all data to analyze
*   
*                                                                          
*  OUTPUT:     
*                   @table				
*                                                                          
*******************************************************************************************/

%macro DescriptiveAnalysis(
	mytable =
);

	%global outname;
	%let outname = CLARO;

	/*
		00. METADATA TREATMENT
	 	=================================
	*/

	/* Get all variables by type to apply different criteria */
	proc contents data=&mytable. out=work.metadatos noprint; run;

	/*data work.metadatos;  
	  set work.metadatos;
	  length rol medida $32.;
	  if upcase(variable)="TARGET" then rol="TARGET";
	  else if upcase(variable) in ("CLNOCL","ANNOMES") then rol="ID";
	  else rol="INPUT";
	  medida="INTERVAL";
	  if upcase(variable) in ("ZIP_CODE", "CC_GOLD_HOLDER_INDICATOR", "CC_PLATINUM_HOLDER_INDICATOR", 
			"CC_REGULAR_HOLDER_INDICATOR", "IS_EMPLOYEE", "ZIP_CODE_RECENT_CHANGE") then medida="NOMINAL"; 
	  if upcase(variable)="TARGET" then medida="BINARY";
	  if substr(upcase(variable),1,8) = "HOLDING_" then medida="NOMINAL";
	  if tipo=2 and upcase(rol) eq "INPUT" then do; medida="NOMINAL"; end;
	run;

	* Dismiss ID variables */
	proc sql;
		update work.metadatos set type=0 where upcase(name) like 'ID^_%' escape '^';
		/*update work.metadatos set type=2 where upcase(name) like 'NUM^_%' escape '^';*/
		update work.metadatos set type=1 where upcase(name) like '%YEAR%';
	quit;

	/* Classify variables per groups */
	data work.metadatos_cat
	  	 work.metadatos_num
		 work.metadatos_date
	;
	  set work.metadatos(keep=name type format);
	  if type = 2 then output work.metadatos_cat;
	  if type = 1 then do;
		if compress(upcase(format)) in ("DATETIME", "DATE") then output work.metadatos_date;
		else output work.metadatos_num;
	  end; 
	run;


	/*
		01. CATEGORICAL VARIABLES
	 	=================================
	*/

	/* Check if there is any CATEGORICAL type variable */
	proc sql noprint;
 		select count(*) into :nobs_cat from work.metadatos_cat;
	quit;

	%if &nobs_cat. > 0 %then %do;

		data _null_; 
		 set work.metadatos_cat end=last; 
			call symput("nameCatVar"||compress(_n_), compress(name));
			if last then call symput("numCatVars", compress(_n_));
		run;

		%do i = 1 %to &nobs_cat.;
			%PlotCategoricalVar(
				 table = &mytable.,
				 var = &&nameCatVar&i..,
				 threshold = 0
			);		
		%end;
	%end;

	/*
		02. NUMERIC VARIABLES
	 	=================================
	*/

	/* Check if there is any NUMERIC type variable */
	proc sql noprint;
 		select count(*) into :nobs_num from work.metadatos_num;
	quit;

	%if &nobs_num. > 0 %then %do;


		data _null_; 
		 set work.metadatos_num end=last; 
			call symput("nameNumVar"||compress(_n_), compress(name));
			if last then call symput("numNumVars", compress(_n_));
		run;

		%do i = 1 %to &numNumVars.;
			%PlotNumericalVar(
				 table = &mytable.,
				 var = &&nameNumVar&i..
			);			
		%end;
	%end;

	/*
		03. DATE VARIABLES
	 	=================================
	*/

	/* Check if there is any DATE type variable */
	proc sql noprint;
 		select count(*) into :nobs_date from work.metadatos_date;
	quit;

	%if &nobs_date. > 0 %then %do;

		data _null_; 
		 set work.metadatos_date end=last; 
			call symput("nameDateVar"||compress(_n_), compress(name));
			if last then call symput("numDateVars", compress(_n_));
		run;

		%do i = 1 %to &numDateVars.;
				%put  table = &mytable.;
			%put	 var = &&nameDateVar&i..;
				%put	 threshold = 1;	
		%end;
	%end;

%mend DescriptiveAnalysis;
