CREATE OR REPLACE PROCEDURE sbxtax."DATAX_PURGE_ORPHANS"
   IS
    affected NUMBER;
BEGIN
    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_AUTHORITIES'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_Authorities
        WHERe authority_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_AUTHORITIES',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_AUTHORITY_LOGIC_GROUP_XREF'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_authority_logic_group_xref
        WHERe authority_logic_group_xref_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_AUTHORITY_LOGIC_GROUP_XREF',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_PRODUCT_CATEGORIES'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_product_categories pc
        WHERe product_category_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_PRODUCT_CATEGORIES',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_RULES'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rules
        WHERe rule_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_RULES',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_RATES'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates
        WHERe rate_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_RATES',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_RATE_TIERS'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rate_tiers
        WHERe rate_tier_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_RATE_TIERS',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_ZONES'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zones
        WHERe zone_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_ZONES',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_ZONE_AUTHORITIES'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zone_authorities
        WHERe zone_authority_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_ZONE_AUTHORITIES',-1);
    COMMIT;

    DELETE FROM datax_check_output dco
    WHERE EXISTS (
        SELECT 1
        FROM datax_checks dc
        WHERE data_owner_table = 'TB_ZONE_MATCH_PATTERNS'
        AND dc.data_check_id = dco.data_check_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zone_match_patterns
        WHERe zone_match_pattern_id = dco.primary_key
    );
    affected := SQL%ROWCOUNT;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (affected||' results deleted because they were orphaned in TB_ZONE_MATCH_PATTERNS',-1);
    COMMIT;
END; -- Procedure


 
 
/