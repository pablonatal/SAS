
PROC SQL;
create table portados as
select count(distinct PORTADO), CUST_ID
from data.claro
group by CUST_ID;
QUIT;

data portados2;
set portados;
if _TEMG001 >1 then output;
run;



proc sql;
select count(1) from data.Resumen_201401;
quit;

proc sql;
select count(distinct cust_id) from data.Resumen_201401;
quit;

/*
EJEMPLOS:
*/


data work.downsell_arpu;
set data.claro;
if cust_id = '6906900' then output;
if cust_id = '8275982' then output;
run;


data work.upsell_arpu;
set data.claro;
if cust_id = '6900530' then output; /* > 20% y 50% */
if cust_id = '8390109' then output; /* > 20% */
run;




8275982
