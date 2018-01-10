CREATE OR REPLACE PROCEDURE content_repo.datacheck_unique_area_zip5 (aplha_zip4_statecodes out varchar2 )
is
vcnt number;
begin

    vcnt := 0;

    select count(1) into vcnt from
    (
        (
        SELECT DISTINCT a_area_id area_id
                                      FROM kpmg_export_areas_file a
                                     WHERE check_kpmg_atleast_3_bounds(a_unique_area) > 1
        minus
        select distinct area_id from kpmg_zip5_export
        )
        union all
         (
         select distinct area_id from kpmg_zip5_export
         minus
         SELECT DISTINCT a_area_id area_id
                                      FROM kpmg_export_areas_file a
                                     WHERE check_kpmg_atleast_3_bounds(a_unique_area) > 1
        )
    );

    if vcnt > 0
    then
         aplha_zip4_statecodes := 'THERE EXISTS FEW THAT MATCHES THE FAILED CRITERIA, FEW STATES GOT FAILED';
         raise_application_error (-20201, 'aplha_zip4_statecodes data check failed, please correct the data');
    end if;
end;
/