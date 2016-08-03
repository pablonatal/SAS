/*********************************************************************************************************
*   NAME: PlotNumericalVar.sas                                                           
*                                                                                                
*   DESCRIPTION OF THE PROGRAM:                                                       
*                                                                                                
* 		Divide table by values (manually typed) of a variables
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
*          	@table(s)	table_&months	
*                                                                          
********************************************************************************************************/



%macro divideTableByMonths(
 table = ,
 var = 
);


data &table._201401
	 &table._201402
	 &table._201403
	 &table._201404
	 &table._201405
	 &table._201406
	 &table._201407
	 &table._201408
	 &table._201409
	 &table._201410
	 &table._201411
	 &table._201412
;
 set &table.;
	if &var. = 201401 then output &table._201401; 
	if &var. = 201402 then output &table._201402; 
	if &var. = 201403 then output &table._201403; 
	if &var. = 201404 then output &table._201404; 
	if &var. = 201405 then output &table._201405; 
	if &var. = 201406 then output &table._201406;
	if &var. = 201407 then output &table._201407;
	if &var. = 201408 then output &table._201408;  
	if &var. = 201409 then output &table._201409;  
	if &var. = 201410 then output &table._201410;  
	if &var. = 201411 then output &table._201411;  
	if &var. = 201412 then output &table._201412;  
run;

%mend divideTableByMonths;
