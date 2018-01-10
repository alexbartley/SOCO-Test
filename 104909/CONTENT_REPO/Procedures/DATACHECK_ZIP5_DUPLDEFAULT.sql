CREATE OR REPLACE PROCEDURE content_repo.datacheck_zip5_dupldefault (aplha_zip4_statecodes out varchar2 )
is
vcnt number;
begin

for i in ( select distinct code from sbxtax.tb_states where us_state = 'Y' )
loop
    vcnt := 0;

    select count(1) into vcnt from
    (
        select count(default_flag), zip, area_id, state_code
        from kpmg_zip5_export
        where default_flag = 'Y'
          and state_code = i.code
        group by zip, area_id, state_code
          having count(default_flag) > 1
    );

    if vcnt > 0
    then
         aplha_zip4_statecodes := aplha_zip4_statecodes||':'||i.code;
         raise_application_error (-20201, 'datacheck_zip5_dupldefault data check failed, please correct the data');
    end if;
end loop;
end;
/