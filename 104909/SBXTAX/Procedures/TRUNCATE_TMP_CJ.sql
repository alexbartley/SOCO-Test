CREATE OR REPLACE PROCEDURE sbxtax."TRUNCATE_TMP_CJ"
as
begin
execute immediate 'truncate table tmp_cj';
end;

/