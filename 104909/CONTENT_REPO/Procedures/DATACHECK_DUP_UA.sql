CREATE OR REPLACE PROCEDURE content_repo.datacheck_dup_ua (aplha_zip4_statecodes out varchar2 )
is
vcnt number;
begin

for i in ( select distinct code from sbxtax.tb_states where us_state = 'Y' )
loop
    vcnt := 0;
    select count(1) into vcnt from (
    select count(a_unique_area), a_state_code, a_area_id from (
    select distinct a_state_code, a_unique_area, a_area_id from kpmg_export_areas_file a
    )
    group by a_area_id, a_state_code having count(a_unique_area) > 1
    );

    if vcnt > 0
    then
         aplha_zip4_statecodes := aplha_zip4_statecodes||':'||i.code;
         raise_application_error (-20201, 'datacheck_dup_ua data check failed, please correct the data');
    end if;
end loop;
end;
/