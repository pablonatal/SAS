

%macro getPopulation(
	ano = ,
	mes = ,
	month = ,
	num_months =
);

	/* Base date in YYYYMM format */
	%let base_date=%sysfunc(putn(%sysfunc(intnx(month,&month,0,b)),YYMMN.));	%put base_date = &base_date;

	/* Months to test */
	%let date_1=%sysfunc(putn(%sysfunc(intnx(month,&month,-1,b)),YYMMN.));		%put date_1 = &date_1;
	%let date_2=%sysfunc(putn(%sysfunc(intnx(month,&month,-2,b)),YYMMN.));		%put date_2 = &date_2;
	%let date_3=%sysfunc(putn(%sysfunc(intnx(month,&month,-3,b)),YYMMN.));		%put date_3 = &date_3;

	

	/* 
		Generation of the master table with all year months available
 	*/
 	%let mes_AUX = &mes;
	%let ano_AUX = &ano;

	data work.MAESTRA_ANO_MES;
		format ANO_LANC 4. MES_LANC 2. ANO_LANC_CHAR $4. MES_LANC_CHAR $2.;
		%do i = 1 %to &num_months;	
			ANO_LANC  = &ano_AUX; 
			MES_LANC  = &mes_AUX;
			ANO_LANC_CHAR  = &ano_AUX;
 			%if &mes_AUX < 10 %then %do; 
				MES_LANC_CHAR  = '0'||substr(put(MES_LANC,$1.),1,1);
			%end;
			%else %do; MES_LANC_CHAR  = &mes_AUX; %end;
				output;
				%let mes_AUX = &mes_AUX-1;
				%if &mes_AUX = 0 %then %do;
					%let mes_AUX = 12;	
					%let ano_AUX = &ano_AUX-1;
			%end;
		 %end;
	run;

	/* Load Macrovars values */
	data _null_;
	 set work.MAESTRA_ANO_MES;
		call symput ("ano"||compress(_n_), compress(ANO_LANC));
		call symput ("mes"||compress(_n_), compress(MES_LANC));
		call symput ("ano_char"||compress(_n_), compress(ANO_LANC_CHAR));
		call symput ("mes_char"||compress(_n_), compress(MES_LANC_CHAR));
	run;


	/* ******************** ************************ *********************** 
		ANALYSIS POPULATION: 
	*********************** *********************** *********************** */

	/* Mes previo para hacer medias */
	proc sql;
		create table work.POPULATION_menos1 as
			select 	CUST_ID,
					ARPU,
					MIN_TRAF_IN_TOTAL,
					MIN_TRAF_TOTAL,
					VALORCARGADO,
					PORTADO,
					MES
		from data.claro_&ano_char4.&mes_char4 b
				;	
	quit;

	/* Mes de análisis */
	proc sql;
		create table work.POPULATION as
			select 	CUST_ID,
					ARPU,
					MIN_TRAF_IN_TOTAL,
					MIN_TRAF_TOTAL,
					VALORCARGADO,
					PORTADO,
					MES
				from data.claro_&ano_char3.&mes_char3 b
				;	
	quit;

	
	/*	*******
		TARGET
	***********	*/

	/* Month M+1*/
	proc sql;
	 create table work.pop_&ano_char2.&mes_char2. as
		select 	CUST_ID,
				ARPU as	ARPU_M1,
				MIN_TRAF_IN_TOTAL as MIN_TRAF_IN_TOTAL_M1,
				MIN_TRAF_TOTAL as MIN_TRAF_TOTAL_M1,
				VALORCARGADO as VALORCARGADO_M1, 
				PORTADO AS PORTADO_M1,
				MES
			from data.claro_&ano_char2.&mes_char2 b
			;	
	run; quit;

	/* Month M+2 */
	proc sql;
	 create table work.pop_&ano_char1.&mes_char1. as
		select 	CUST_ID,
				ARPU as	ARPU_M2,
				MIN_TRAF_IN_TOTAL as MIN_TRAF_IN_TOTAL_M2,
				MIN_TRAF_TOTAL as MIN_TRAF_TOTAL_M2,
				VALORCARGADO as VALORCARGADO_M2, 
				PORTADO AS PORTADO_M2,
				MES
			from data.claro_&ano_char1.&mes_char1 b
			;	
	run; quit;

	/* ********************************
		medias para up/down ARPU
	******************************** */
	proc append base=work.medias_p data= work.POPULATION force; run;
	proc append base=work.medias_p data= work.POPULATION_menos1 force; run;

	proc append base=work.medias_t data= work.pop_&ano_char1.&mes_char1. force; run;
	proc append base=work.medias_t data= work.pop_&ano_char2.&mes_char2. force; run;
	
	data work.medias_p;
	 set work.medias_p
	 if ARPU = . then ARPU = 0;
	run;

	data work.medias_t;
	 set work.medias_t;
	 if ARPU_M1 = . then ARPU_M1 = 0;
	 if ARPU_M2 = . then ARPU_M2 = 0;
	run;

	proc sql;
	 create table work.medias_p as
		select CUST_ID, avg(ARPU) as ARPU_avg_pop
		from work.medias_p
		group by CUST_ID
	quit;

	proc sql;
	 create table work.medias_t as
		select CUST_ID, sum(ARPU_M1+ARPU_M2)/2 as ARPU_avg_target
		from work.medias_t
		group by CUST_ID
	quit;


	/* *******
		JOIN
	******* */
	proc sort data=	work.POPULATION; by CUST_ID; run;
	proc sort data=	work.pop_&ano_char1.&mes_char1.; by CUST_ID; run;
	proc sort data=	work.pop_&ano_char2.&mes_char2.; by CUST_ID; run;
	proc sort data=	work.medias_p; by CUST_ID; run;
	proc sort data=	work.medias_t; by CUST_ID; run;

	data work.pop_&ano_char3.&mes_char3.;
	 merge 	work.POPULATION(in=a)
			work.pop_&ano_char2.&mes_char1.(in=b) /* Mes M+1 */
			work.pop_&ano_char3.&mes_char2.(in=c) /* Mes M+2 */
			work.medias_p (in=d)
			work.medias_p (in=e)
		;
		by CUST_ID;
		if a /*and SAVINGS_BALANCE > 0 */ then do;
		
			if a and not b then TARGET_BAJA_M1 = 1;			else TARGET_BAJA_M1 = 0;
			if a and not b and not c then TARGET_BAJA_M2 = 1;	else TARGET_BAJA_M2 = 0;

			if (a and b and c) and VALORCARGADO > 0 and VALORCARGADO_M1 = 0 then TARGET_INACTIVO_CARGA_M1 = 1;	 else TARGET_INACTIVO_CARGA_M1 = 0;
			if (a and b and c) and VALORCARGADO > 0 and VALORCARGADO_M1 = 0 and VALORCARGADO_M2 = 0 then TARGET_INACTIVO_CARGA_M2 = 1;	else TARGET_INACTIVO_CARGA_M2 = 0;
			if (a and b and c) and (MIN_TRAF_IN_TOTAL>0 or MIN_TRAF_TOTAL>0) and MIN_TRAF_TOTAL_M1=0 and MIN_TRAF_IN_TOTAL_M1=0 then TARGET_INACTIVO_MIN_M1 = 1;	 else TARGET_INACTIVO_MIN_M1 = 0;
			if (a and b and c) and (MIN_TRAF_IN_TOTAL>0 or MIN_TRAF_TOTAL>0) and MIN_TRAF_TOTAL_M1=0 and MIN_TRAF_IN_TOTAL_M1=0 and MIN_TRAF_TOTAL_M2=0 and MIN_TRAF_IN_TOTAL_M2=0 then TARGET_INACTIVO_MIN_M2 = 1;	 else TARGET_INACTIVO_MIN_M2 = 0;
			
			/*Downsell*/
			if (a and b and c) and ( (ARPU_M1-ARPU) < (-0.10*ARPU)) then TARGET_10PCT_M1 = 1; else TARGET_10PCT_M1 = 0;
			if (a and b and c) and ( (ARPU_M1-ARPU) < 0 and (ARPU_M2-ARPU) < (-0.10*ARPU)) then TARGET_10PCT_M2 = 1; else TARGET_10PCT_M2 = 0;

			if (a and b and c) and ( (ARPU_M1-ARPU) < (-0.20*ARPU)) then TARGET_20PCT_M1 = 1; else TARGET_20PCT_M1 = 0;
			if (a and b and c) and ( (ARPU_M1-ARPU) < 0 and (ARPU_M2-ARPU) < (-0.20*ARPU)) then TARGET_20PCT_M2 = 1; else TARGET_20PCT_M2 = 0;

			if (a and b and c) and ( (ARPU_M1-ARPU) < (-0.50*ARPU)) then TARGET_50PCT_M1 = 1; else TARGET_50PCT_M1 = 0;
			if (a and b and c) and ( (ARPU_M1-ARPU) < 0 and (ARPU_M2-ARPU) < (-0.50*ARPU)) then TARGET_50PCT_M2 = 1; else TARGET_50PCT_M2 = 0;

			/* Upsell */


			/* Portado */
			if (a and b and c) and PORTADO = 'NATIVO' and PORTADO_M1 ne 'NATIVO' and PORTADO_M2 ne 'NATIVO' then TARGET_PORTADO = 1; else  TARGET_PORTADO = 0;
			if (a and b and c) and PORTADO = 'NATIVO' and PORTADO_M1 eq 'IN' and PORTADO_M2 eq 'IN' then TARGET_PORTADO_IN = 1; else  TARGET_PORTADO_IN = 0;
			if (a and b and c) and PORTADO = 'NATIVO' and PORTADO_M1 eq 'OUT' and PORTADO_M2 eq 'OUT' then TARGET_PORTADO_OUT = 1; else  TARGET_PORTADO_OUT = 0;

		output;
		end;
	run;


	/*	*******
		SUMMARY
	***********	*/

	proc sql noprint;
	select count(*) into :population
		from work.pop_&ano_char3.&mes_char3.;
	quit;

	proc sql;
	create table work.summary as
	 select &ano_char3.&mes_char3. as yearmonth,
	 		&population as POPULATION,

			sum(TARGET_BAJA_M1) as TARGET_BAJA_M1,
			sum(TARGET_BAJA_M2) as TARGET_BAJA_M2,

			sum(TARGET_INACTIVO_CARGA_M1) as TARGET_INACTIVO_CARGA_M1,
			sum(TARGET_INACTIVO_CARGA_M2) as TARGET_INACTIVO_CARGA_M2,
			sum(TARGET_INACTIVO_MIN_M1) as TARGET_INACTIVO_MIN_M1,
			sum(TARGET_INACTIVO_MIN_M2) as TARGET_INACTIVO_MIN_M2,

			sum(TARGET_10PCT_M1) as TARGET_10PCT_M1,
			sum(TARGET_10PCT_M2) as TARGET_10PCT_M2,
			sum(TARGET_20PCT_M1) as TARGET_20PCT_M1,
			sum(TARGET_20PCT_M2) as TARGET_20PCT_M2,
			sum(TARGET_50PCT_M1) as TARGET_50PCT_M1,
			sum(TARGET_50PCT_M2) as TARGET_50PCT_M2,

			sum(TARGET_PORTADO) as TARGET_PORTADO,
			sum(TARGET_PORTADO_IN) as TARGET_PORTADO_IN,
			sum(TARGET_PORTADO_OUT) as TARGET_PORTADO_OUT

		from work.pop_&ano_char3.&mes_char3.
	;
	quit;

	proc append base=data.summary data= work.summary force;
	run;



%mend getPopulation;

%getPopulation(	ano = 2014, mes = 12, month='1DEC2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 11, month='1NOV2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 10, month='1OCT2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 09, month='1SEP2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 08, month='1AUG2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 07, month='1JUL2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 06, month='1JUN2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 05, month='1MAY2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 04, month='1APR2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 03, month='1MAR2014'd, num_months = 4 );


/*%getPopulation(	ano = 2014, mes = 04, month='1APR2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 03, month='1MAR2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 02, month='1FEB2014'd, num_months = 4 );
%getPopulation(	ano = 2014, mes = 01, month='1JAN2014'd, num_months = 4 );

%getPopulation(	ano = 2013, mes = 12, month='1DEC2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 11, month='1NOV2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 10, month='1OCT2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 09, month='1SEP2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 08, month='1AUG2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 07, month='1JUL2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 06, month='1JUN2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 05, month='1MAY2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 04, month='1APR2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 03, month='1MAR2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 02, month='1FEB2013'd, num_months = 4 );
%getPopulation(	ano = 2013, mes = 01, month='1JAN2013'd, num_months = 4 );


%getPopulation(	ano = 2012, mes = 12, month='1DEC2012'd, num_months = 4 );
%getPopulation(	ano = 2012, mes = 11, month='1NOV2012'd, num_months = 4 );
%getPopulation(	ano = 2012, mes = 10, month='1OCT2012'd, num_months = 4 );
%getPopulation(	ano = 2012, mes = 09, month='1SEP2012'd, num_months = 4 );
%getPopulation(	ano = 2012, mes = 08, month='1AUG2012'd, num_months = 4 );
%getPopulation(	ano = 2012, mes = 07, month='1JUL2012'd, num_months = 4 );
*/
