CREATE OR REPLACE PROCEDURE content_repo.datacheck_zip4_duparea (aplha_zip4_statecodes out varchar2 )
is
vcnt number;
begin

for i in ( select distinct code from sbxtax.tb_states where us_state = 'Y' )
loop
    vcnt := 0;

    select count(1) into vcnt from
    (
        select count(distinct area_id), zip, plus4_range from kpmg_zip4_export
         where state_code = i.code
         group by zip, plus4_range
         having count(distinct area_id) >1
    );

    if vcnt > 0
    then
         aplha_zip4_statecodes := aplha_zip4_statecodes||':'||i.code;
         raise_application_error (-20201, 'datacheck_zip4_duparea data check failed, please correct the data');
    end if;
end loop;
end;
/