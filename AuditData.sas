
libname data 'C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\data'; 

proc printto log = "C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\meses.log";
run;

ods listing close;
ods html file='C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\output';

/* **********************************
	01 - CARGA DE TABLAS

	 CANTCARGAS               
	 CANT_MS                  
	 COD_PLAN                 
	 CUST_ID                  
	 DES                      
	 DISC_REASON              
	 KB_CONSUMO               
	 MENSAJES                 
	 MES                      
	 MIN_TRAF_AVANTEL         
	 MIN_TRAF_BELLSOUTH       
	 MIN_TRAF_COMCEL          
	 MIN_TRAF_IN_AVANTEL      
	 MIN_TRAF_IN_BELLSOUTH    
	 MIN_TRAF_IN_COMCEL       
	 MIN_TRAF_IN_LDINT        
	 MIN_TRAF_IN_LDNAL        
	 MIN_TRAF_IN_OLA          
	 MIN_TRAF_LDINT           
	 MIN_TRAF_LDNAL           
	 MIN_TRAF_OLA             
	 NRN                      
	 PLAN_FINAL               
	 PORTADO                  
	 VALORCARGADO             
	 VLR_MENSAJES             
	 VLR_MS                   
	 anyomes  
************************************* */

/* Minutos*/
PROC IMPORT OUT= data.Minutos 
            DATAFILE= "C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\500mil_sms_minIn.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
     GUESSINGROWS=100; 
RUN;

/* Resumen */
PROC IMPORT OUT= data.resumen 
            DATAFILE= "C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\RESUMEN_500MIL_arpu_traf_out.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
     GUESSINGROWS=100; 
RUN;

PROC IMPORT OUT= data.gprs 
            DATAFILE= "C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\resumen_gprs_500mil_acce.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
     GUESSINGROWS=100; 
RUN;

data data.Resumen (drop=end_serv_d);
set data.Resumen;
anyomes = cat(substr(scan(end_serv_d,3,'/'),1,4), scan(end_serv_d,2,'/'));
run;

/* **********************************
	02 - AUDITORIA PARA TODOS LOS MESES
************************************* */

/* Describe all tables for all months */
%DescriptiveAnalysis( mytable = data.Minutos );
%DescriptiveAnalysis( mytable = data.resumen );
%DescriptiveAnalysis( mytable = data.gprs );


/*Conteos por anyo-mes */
proc sql; create table meses_Minutos as select mes, count(1) from data.Minutos group by MES; quit;
proc sql; create table meses_resumen as select mes, count(1) from data.resumen group by MES; quit;
proc sql; create table meses_gprs as select mes, count(1) from data.gprs group by MES; quit;

data data.CLARO_ALL_CAT;
set All_CAT;
run;

/* **********************************
	03 - AUDITORIA MES A MES
************************************* */

%divideTableByMonths( table = data.Minutos , var = MES );
%divideTableByMonths( table = data.resumen , var = MES );
%divideTableByMonths( table = data.gprs, var = MES );

%DescriptiveAnalysis( mytable = data.Minutos_201401); 
%DescriptiveAnalysis( mytable = data.Minutos_201402); 
%DescriptiveAnalysis( mytable = data.Minutos_201403); 
%DescriptiveAnalysis( mytable = data.Minutos_201404); 
%DescriptiveAnalysis( mytable = data.Minutos_201405); 
%DescriptiveAnalysis( mytable = data.Minutos_201406);
%DescriptiveAnalysis( mytable = data.Minutos_201407);
%DescriptiveAnalysis( mytable = data.Minutos_201408);  
%DescriptiveAnalysis( mytable = data.Minutos_201409);  
%DescriptiveAnalysis( mytable = data.Minutos_201410);  
%DescriptiveAnalysis( mytable = data.Minutos_201411);  
%DescriptiveAnalysis( mytable = data.Minutos_201412);  

%DescriptiveAnalysis( mytable = data.Resumen_201401); 
%DescriptiveAnalysis( mytable = data.Resumen_201402); 
%DescriptiveAnalysis( mytable = data.Resumen_201403); 
%DescriptiveAnalysis( mytable = data.Resumen_201404); 
%DescriptiveAnalysis( mytable = data.Resumen_201405); 
%DescriptiveAnalysis( mytable = data.Resumen_201406);
%DescriptiveAnalysis( mytable = data.Resumen_201407);
%DescriptiveAnalysis( mytable = data.Resumen_201408);  
%DescriptiveAnalysis( mytable = data.Resumen_201409);  
%DescriptiveAnalysis( mytable = data.Resumen_201410);  
%DescriptiveAnalysis( mytable = data.Resumen_201411);  
%DescriptiveAnalysis( mytable = data.Resumen_201412); 

%DescriptiveAnalysis( mytable = data.Gprs_201401); 
%DescriptiveAnalysis( mytable = data.Gprs_201402); 
%DescriptiveAnalysis( mytable = data.Gprs_201403); 
%DescriptiveAnalysis( mytable = data.Gprs_201404); 
%DescriptiveAnalysis( mytable = data.Gprs_201405); 
%DescriptiveAnalysis( mytable = data.Gprs_201406);
%DescriptiveAnalysis( mytable = data.Gprs_201407);
%DescriptiveAnalysis( mytable = data.Gprs_201408);  
%DescriptiveAnalysis( mytable = data.Gprs_201409);  
%DescriptiveAnalysis( mytable = data.Gprs_201410);  
%DescriptiveAnalysis( mytable = data.Gprs_201411);  
%DescriptiveAnalysis( mytable = data.Gprs_201412); 


data data.Claro_cat_monthly;
set Claro_cat;
run;

data data.Claro_num_monthly;
set Claro_num;
run;



/*
	MERGE ALL DATA
*/
proc sort data=	data.Gprs; by CUST_ID COD_PLAN MES ; run;
proc sort data=	data.Minutos; by CUST_ID COD_PLAN MES ; run;
proc sort data=	data.Resumen; by CUST_ID COD_PLAN MES ; run;

data data.claro;
 merge 	data.Gprs (in=a)
		data.Minutos (in=b) 
		data.Resumen (in=c) 
	;
	by CUST_ID COD_PLAN MES;
	if a or b or c then output;
run;

* proc contents data= data.claro out=work.contents;
* run;


data data.claro;
 set data.claro;
 	if KB_CONSUMO = . then KB_CONSUMO = 0;
	if MIN_TRAF_AVANTEL = . then MIN_TRAF_AVANTEL = 0;
	if MIN_TRAF_BELLSOUTH = . then MIN_TRAF_BELLSOUTH = 0;
	if MIN_TRAF_COMCEL = . then MIN_TRAF_COMCEL = 0;
	if MIN_TRAF_LDINT = . then MIN_TRAF_LDINT = 0;
	if MIN_TRAF_LDNAL = . then MIN_TRAF_LDNAL = 0;
	if MIN_TRAF_OLA = . then MIN_TRAF_OLA = 0;
	if MIN_TRAF_IN_AVANTEL = . then MIN_TRAF_IN_AVANTEL = 0;
	if MIN_TRAF_IN_BELLSOUTH = . then MIN_TRAF_IN_BELLSOUTH = 0;
	if MIN_TRAF_IN_COMCEL = . then MIN_TRAF_IN_COMCEL = 0;
	if MIN_TRAF_IN_LDINT = . then MIN_TRAF_IN_LDINT = 0;
	if MIN_TRAF_IN_LDNAL = . then MIN_TRAF_IN_LDNAL = 0;
	if MIN_TRAF_IN_OLA = . then MIN_TRAF_IN_OLA = 0;
	MIN_TRAF_TOTAL = MIN_TRAF_AVANTEL + MIN_TRAF_BELLSOUTH + MIN_TRAF_COMCEL + MIN_TRAF_LDINT + MIN_TRAF_LDNAL + MIN_TRAF_OLA;
	MIN_TRAF_IN_TOTAL = MIN_TRAF_IN_AVANTEL + MIN_TRAF_IN_BELLSOUTH + MIN_TRAF_IN_COMCEL + MIN_TRAF_IN_LDINT + MIN_TRAF_IN_LDNAL + MIN_TRAF_IN_OLA;
run; 

%divideTableByMonths( table = data.claro , var = MES );
