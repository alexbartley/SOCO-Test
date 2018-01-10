CREATE OR REPLACE PROCEDURE content_repo.datacheck_aplha_zip4 (aplha_zip4_statecodes out varchar2 )
is
vcnt number;
begin

for i in ( select distinct code from sbxtax.tb_states where us_state = 'Y' )
loop
    vcnt := 0;
    select count(1) into vcnt from kpmg_zip4_export
     where state_code = i.code and ascii(plus4_range) between 65 and 90;

    if vcnt > 0
    then
         aplha_zip4_statecodes := aplha_zip4_statecodes||':'||i.code;
         raise_application_error (-20201, 'datacheck_aplha_zip4 data check failed, please correct the data');
    end if;
end loop;
end;
/