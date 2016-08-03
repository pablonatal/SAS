
libname data 'C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\data'; 

proc printto log = "C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\meses.log";
run;

ods listing close;
ods html file='C:\Users\pablo.natal\Documents\PROYECTOS\PROPUESTAS\Claro\output';

/* **********************************
	01 - CARGA DE TABLAS
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
