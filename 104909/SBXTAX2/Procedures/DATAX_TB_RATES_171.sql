CREATE OR REPLACE PROCEDURE sbxtax2.DATAX_TB_RATES_171
   ( taxDataProviderId IN NUMBER,runId IN OUT NUMBER)
   IS
   --<data_check id="171" name="Unmatched Active Rates between Brazil ICMS and ICMS-ST Authorities.">
   dataCheckId NUMBER := -793;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_171 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT distinct coalesce(icms.rate_id,icmsst.rate_id), dataCheckId, runId, SYSDATE
    --select icms.name icms_authority, icms.rate_code icms_rate_code, icms.start_date icms_start, icms.end_date icms_end, icms.rate icms_rate,
    --    icmsst.name icmsst_authority, icmsst.rate_code icmsst_rate_code, icmsst.start_date icmsst_start, icmsst.end_date icmst_end, icmsst.rate icmsst_rate
    from (
        select a.authority_id, replace(a.name, 'ICMS ') name, rate_code, start_date, end_Date, rate, r.rate_id
        from tb_authorities a
        join tb_rates r on (r.authority_id = a.authority_id and r.merchant_id = a.merchant_id)
        where a.name like '%ICMS %' 
        and a.name not like '%ICMS Credit%'
        and a.name not like 'Brazil ICMS Amazonas Stimulus Credit'
        and r.end_date is null
        ) icms
    full outer join (
        select a.authority_id, replace(a.name, 'ICMS-ST ') name,rate_code, start_date, end_Date, rate, r.rate_id
        from tb_authorities a
        join tb_rates r on (r.authority_id = a.authority_id and r.merchant_id = a.merchant_id)
        where a.name like '%ICMS-ST %' 
        and r.end_date is null
        ) icmsst 
    on (icms.name = icmsst.name and icms.rate_code = icmsst.rate_Code and icms.start_date = icmsst.start_date)
    where ((icms.rate_code is null 
    or icmsst.rate_code is null)
    or nvl(icms.rate,-1) != nvl(icmsst.rate,-1))
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = coalesce(icms.rate_id,icmsst.rate_id)
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_171 finished.',runId);
    COMMIT;
END;
 
 
/