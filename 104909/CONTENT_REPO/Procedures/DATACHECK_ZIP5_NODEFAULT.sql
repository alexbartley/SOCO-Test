CREATE OR REPLACE PROCEDURE content_repo.datacheck_zip5_nodefault (aplha_zip4_statecodes out varchar2 )
is
vcnt number;
begin

for i in ( select distinct code from sbxtax.tb_states where us_state = 'Y' )
loop
    vcnt := 0;

        select count(1) into vcnt from kpmg_zip5_export a where state_code = i.code
          and default_flag = 'N' and not exists (
          select 1 from kpmg_zip5_export b where a.state_code = b.state_code and a.zip = b.zip and b.default_flag = 'Y'
          );

    if vcnt > 0
    then
         aplha_zip4_statecodes := aplha_zip4_statecodes||':'||i.code;
         raise_application_error (-20201, 'datacheck_zip5_nodefault data check failed, please correct the data');
    end if;
end loop;
end;
/