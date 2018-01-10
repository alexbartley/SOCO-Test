CREATE OR REPLACE PROCEDURE sbxtax2.datax_qa_compare
   IS
updated_count NUMBER;
remaining_count NUMBER;
tlrId VARCHAR2(50) := 'UNKNOWN';
BEGIN


--Automatically approve anything that Tax Research reported
--AUTHORITIES
UPDATE datax_check_output co
SET reviewed_approved = tlrId, approved_Date = SYSDATE, verified = tlrId, verified_Date = SYSDATE
WHERE reviewed_approved IS NULL
AND EXISTS (
    SELECT 1
    FROM datax_tb_authorities_vw av2, (
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output co, datax_tb_authorities_vw av
        WHERE co.reviewed_approved IS NULL
        AND co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
        INTERSECT
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output@dxmaster co, datax_tb_authorities_vw@dxmaster av
        WHERE co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
    ) sub
    WHERE av2.data_check_id = sub.data_check_id
    AND av2.record_key = sub.record_key
    AND av2.primary_key = co.primary_key
    AND av2.data_check_id = co.data_Check_id
);
updated_count := updated_count+SQL%ROWCOUNT;
COMMIT;
--RULES
UPDATE datax_check_output co
SET reviewed_approved = tlrId, approved_Date = SYSDATE, verified = tlrId, verified_Date = SYSDATE
WHERE reviewed_approved IS NULL
AND EXISTS (
    SELECT 1
    FROM datax_tb_rules_vw av2, (
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output co, datax_tb_rules_vw av
        WHERE co.reviewed_approved IS NULL
        AND co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
        INTERSECT
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output@dxmaster co, datax_tb_rules_vw@dxmaster av
        WHERE co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
    ) sub
    WHERE av2.data_check_id = sub.data_check_id
    AND av2.record_key = sub.record_key
    AND av2.primary_key = co.primary_key
    AND av2.data_check_id = co.data_Check_id
);
updated_count := updated_count+SQL%ROWCOUNT;
COMMIT;
--RATES
UPDATE datax_check_output co
SET reviewed_approved = tlrId, approved_Date = SYSDATE, verified = tlrId, verified_Date = SYSDATE
WHERE reviewed_approved IS NULL
AND EXISTS (
    SELECT 1
    FROM datax_tb_rates_vw av2, (
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output co, datax_tb_rates_vw av
        WHERE co.reviewed_approved IS NULL
        AND co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
        INTERSECT
        SELECT av.record_key, co.data_Check_id
        FROM  datax_check_output@dxmaster co, datax_tb_rates_vw@dxmaster av
        WHERE co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
    ) sub
    WHERE av2.data_check_id = sub.data_check_id
    AND av2.record_key = sub.record_key
    AND av2.primary_key = co.primary_key
    AND av2.data_check_id = co.data_Check_id
);
updated_count := updated_count+SQL%ROWCOUNT;
COMMIT;
--ZONES
UPDATE datax_check_output co
SET reviewed_approved = tlrId, approved_Date = SYSDATE, verified = tlrId, verified_Date = SYSDATE
WHERE reviewed_approved IS NULL
AND EXISTS (
    SELECT 1
    FROM datax_tb_zones_vw av2, (
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output co, datax_tb_zones_vw av
        WHERE co.reviewed_approved IS NULL
        AND co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
        INTERSECT
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output@dxmaster co, datax_tb_zones_vw@dxmaster av
        WHERE co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
    ) sub
    WHERE av2.data_check_id = sub.data_check_id
    AND av2.record_key = sub.record_key
    AND av2.primary_key = co.primary_key
    AND av2.data_check_id = co.data_Check_id
);
updated_count := updated_count+SQL%ROWCOUNT;
COMMIT;
--PRODUCT CATEGORIES
UPDATE datax_check_output co
SET reviewed_approved = tlrId, approved_Date = SYSDATE, verified = tlrId, verified_Date = SYSDATE
WHERE reviewed_approved IS NULL
AND EXISTS (
    SELECT 1
    FROM datax_tb_product_cat_vw av2, (
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output co, datax_tb_product_cat_vw av
        WHERE co.reviewed_approved IS NULL
        AND co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
        INTERSECT
        SELECT av.record_key, co.data_Check_id
        FROM datax_check_output@dxmaster co, datax_tb_product_cat_vw@dxmaster av
        WHERE co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
    ) sub
    WHERE av2.data_check_id = sub.data_check_id
    AND av2.record_key = sub.record_key
    AND av2.primary_key = co.primary_key
    AND av2.data_check_id = co.data_Check_id
);
updated_count := updated_count+SQL%ROWCOUNT;
COMMIT;
--ZONE AUTHORITY MAPPINGS
UPDATE datax_check_output co
SET reviewed_approved = tlrId, approved_Date = SYSDATE, verified = tlrId, verified_Date = SYSDATE
WHERE reviewed_approved IS NULL
AND EXISTS (
    SELECT 1
    FROM datax_tb_zone_auth_vw av2, (
        SELECT co.data_Check_id, av.authority_name, av.zone_1_name,
            av.zone_2_name, av.zone_2_level,
            av.zone_3_name, av.zone_3_level,
            av.zone_4_name, av.zone_4_level,
            av.zone_5_name, av.zone_5_level,
            av.zone_6_name, av.zone_6_level,
            av.zone_7_name, av.zone_7_level
        FROM datax_check_output co, datax_tb_zone_auth_vw av
        WHERE co.reviewed_approved IS NULL
        AND co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
        INTERSECT
        SELECT co.data_Check_id, av.authority_name, av.zone_1_name,
            av.zone_2_name, av.zone_2_level,
            av.zone_3_name, av.zone_3_level,
            av.zone_4_name, av.zone_4_level,
            av.zone_5_name, av.zone_5_level,
            av.zone_6_name, av.zone_6_level,
            av.zone_7_name, av.zone_7_level
        FROM datax_check_output@dxmaster co, datax_tb_zone_auth_vw@dxmaster av
        WHERE co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
    ) sub
    WHERE av2.data_check_id = sub.data_check_id
    AND NVL(sub.zone_2_name,'ZONE_2_NAME') = NVL(av2.zone_2_name,'ZONE_2_NAME')
    AND NVL(sub.zone_3_name,'ZONE_3_NAME') = NVL(av2.zone_3_name,'ZONE_3_NAME')
    AND NVL(sub.zone_4_name,'ZONE_4_NAME') = NVL(av2.zone_4_name,'ZONE_4_NAME')
    AND NVL(sub.zone_5_name,'ZONE_5_NAME') = NVL(av2.zone_5_name,'ZONE_5_NAME')
    AND NVL(sub.zone_6_name,'ZONE_6_NAME') = NVL(av2.zone_6_name,'ZONE_6_NAME')
    AND NVL(sub.zone_7_name,'ZONE_7_NAME') = NVL(av2.zone_7_name,'ZONE_7_NAME')
    AND av2.primary_key = co.primary_key
    AND av2.data_check_id = co.data_Check_id
);
updated_count := updated_count+SQL%ROWCOUNT;
COMMIT;
--ZONE ALIAS
UPDATE datax_check_output co
SET reviewed_approved = tlrId, approved_Date = SYSDATE, verified = tlrId, verified_Date = SYSDATE
WHERE reviewed_approved IS NULL
AND EXISTS (
    SELECT 1
    FROM datax_tb_zone_alias_vw av2, (
        SELECT av.pattern, av.value, av.type, co.data_Check_id
        FROM datax_check_output co, datax_tb_zone_alias_vw av
        WHERE co.reviewed_approved IS NULL
        AND co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
        INTERSECT
        SELECT av.pattern, av.value, av.type, co.data_Check_id
        FROM datax_check_output@dxmaster co, datax_tb_zone_alias_vw@dxmaster av
        WHERE co.data_check_id = av.data_check_id
        AND co.primary_key = av.primary_key
    ) sub
    WHERE av2.data_check_id = sub.data_check_id
    AND av2.pattern = sub.pattern
    AND av2.value = sub.value
    AND av2.type = sub.type
    AND av2.primary_key = co.primary_key
    AND av2.data_check_id = co.data_Check_id
);
updated_count := updated_count+SQL%ROWCOUNT;
COMMIT;

--Report List of any results by DataCheckId that do not match Tax Research
SELECT COUNT(*) num_of_unapproved_results
INTO remaining_count
FROM datax_checks dc, datax_check_output co
WHERE dc.data_Check_id = co.data_Check_id
AND co.reviewed_approved IS NULL;


DBMS_OUTPUT.put_line(updated_count||' records approved compared to Tax Research. '||remaining_count||' records still need to be approved.');


END; -- Procedure
/