CREATE OR REPLACE PROCEDURE sbxtax.datax_tb_compl_areas_198
(runId IN OUT NUMBER)
is
   --<data_check id="198" name="Check for Incorrect Compliance Area Mappings" >
   dataCheckId NUMBER := -999;
   vlocal_step varchar2(100);
   err_num number;
   err_msg varchar2(4000);
begin

    vlocal_step := 'DATAX_TB_COMPL_AREAS_198 STEP 0';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_COMPL_AREAS_198 started.',runId) RETURNING run_id INTO runId;
    COMMIT;

    vlocal_step := 'DATAX_TB_COMPL_AREAS_198 STEP 1';
    -- Checking for old dated dates and end date overlapping
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date)
    (
        SELECT tca.compliance_area_id, dataCheckId, runId, SYSDATE
        FROM tb_compliance_areas tca
        WHERE START_DATE < '01-Jan-1900' and end_date < start_date
    );

    -- Checking for end date which is less than the start_date
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date)
    (
        SELECT tca.compliance_area_id, dataCheckId, runId, SYSDATE
        FROM tb_compliance_areas tca
        WHERE START_DATE > '01-Jan-1900' and end_date < start_date
    );

    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date)
    (
        SELECT tca.compliance_area_id, dataCheckId, runId, SYSDATE
        FROM tb_compliance_areas tca
        WHERE START_DATE > '01-Jan-1900' and end_date < start_date
    );

    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date)
    (
        select tc1.compliance_area_auth_id, dataCheckId, runId, SYSDATE
          from tb_comp_area_authorities tc1
         where not exists (
                            select 1 from tb_compliance_areas tc2
                             where tc1.compliance_area_id = tc2.compliance_area_id
                            )
    );

     INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date)
    (
        select tc1.compliance_area_id, dataCheckId, runid, sysdate
          from tb_compliance_areas tc1
         where not exists ( select 1 from tb_comp_area_authorities tc2
                             where tc1.compliance_area_id = tc2.compliance_area_id
                           )

    );

    -- different compliance areas that were associatedd with the same list of authorities
    /*
    insert into tmp_datax_check_output(data_check_output_id, step_info, primary_key, data_check_id, run_id, creation_date)
    (
        select 1, auth_list, compliance_area_id, datacheckid, runid, sysdate
         from ( select LISTAGG (authority_id, ',') WITHIN GROUP (ORDER BY compliance_area_id) auth_list,
                                                    compliance_area_id from tb_comp_area_authorities
                                                    GROUP BY compliance_area_id
                                                    )
         where auth_list in ( SELECT authority_list fROM (SELECT LISTAGG (authority_id, ',') wITHIN GROUP (ORDER BY compliance_area_id )
                               authority_list, compliance_area_id FROM tb_comp_area_authorities GROUP BY compliance_area_id
                                ) GROUP BY authority_list HAVING COUNT (compliance_area_id) > 1
                            )
    );
    */
end;
/