CREATE OR REPLACE PROCEDURE content_repo.datacheck_inzip4_notin_zip5 (aplha_zip4_statecodes out varchar2 )
is
vcnt number;
begin

for i in ( select distinct code from sbxtax.tb_states where us_state = 'Y' )
loop
    vcnt := 0;

    select count(1) into vcnt from
    (
        select distinct zip, state_code from kpmg_zip4_export where state_code = i.code
        minus
        select distinct zip, state_code from kpmg_zip5_export where state_code = i.code
    );

    if vcnt > 0
    then
         aplha_zip4_statecodes := aplha_zip4_statecodes||':'||i.code;
         raise_application_error (-20201, 'datacheck_inzip4_notin_zip5 data check failed, please correct the data');
    end if;
end loop;
end;
/