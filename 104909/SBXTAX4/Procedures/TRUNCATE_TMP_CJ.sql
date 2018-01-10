CREATE OR REPLACE procedure sbxtax4.truncate_tmp_cj
as 
begin 
execute immediate 'truncate table SBXTAX.tmp_cj'; 
end;
 
 
 
/