CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_97
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="97" name="Check for Double Mapped Authorities" >
   dataCheckId NUMBER := -720;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_97 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT zone_authority_id, dataCheckId, runId, SYSDATE
    from (
        select /*+ opt_param('_optimizer_join_factorization','false') */ distinct cza.zone_authority_id
        from ct_zone_Authorities cza, (
            select za1.authority_name, za1.primary_key zone_a, za2.primary_key zone_b
            from ct_zone_authorities za1,ct_zone_authorities za2, tb_authorities a
            where nvl(za1.reverse_flag,'N') = nvl(za2.reverse_flag,'N')
            and nvl(za1.reverse_flag,'N') = 'N'
            and a.name = za1.authority_name
            and za1.authority_name = za2.authority_name
            and za2.zone_3_name = za1.zone_3_name
            and za2.zone_4_name = za1.zone_4_name
            and za1.zone_4_name IS NOT NULL
            and za1.zone_5_name IS NULL
            and za1.primary_key != za2.primary_key
            union
            select distinct za1.authority_name, za1.primary_key zone_a, za2.primary_key zone_b
            from ct_zone_authorities za1, ct_zone_authorities za2, tb_authorities a
            where nvl(za1.reverse_flag,'N') = nvl(za2.reverse_flag,'N')
            and nvl(za1.reverse_flag,'N') = 'N'
            and a.name = za1.authority_name
            and za1.authority_name = za2.authority_name
            and za2.zone_3_name = za1.zone_3_name
            and za2.zone_4_name = za1.zone_4_name
            and za2.zone_5_name = za1.zone_5_name
            and za1.zone_5_name IS NOT NULL
            and za1.zone_6_name IS NULL
            and za1.primary_key != za2.primary_key
            union
            select distinct za1.authority_name, za1.primary_key zone_a, za2.primary_key zone_b
            from ct_zone_authorities za1, ct_zone_authorities za2, tb_authorities a
            where nvl(za1.reverse_flag,'N') = nvl(za2.reverse_flag,'N')
            and nvl(za1.reverse_flag,'N') = 'N'
            and a.name = za1.authority_name
            and za1.authority_name = za2.authority_name
            and za2.zone_3_name = za1.zone_3_name
            and za2.zone_4_name = za1.zone_4_name
            and za2.zone_5_name = za1.zone_5_name
            and za2.zone_6_name = za1.zone_6_name
            and za1.zone_6_name IS NOT NULL
            and za1.zone_7_name IS NULL
            and za1.primary_key != za2.primary_key
        ) reports
        where cza.authority_name = reports.authority_name
        and (cza.primary_key = reports.zone_a or cza.primary_key = reports.zone_b)
    )
    WHERE NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = zone_authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_97 finished.',runId);
END;
 
 
/