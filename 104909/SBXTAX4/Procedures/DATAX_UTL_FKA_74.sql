CREATE OR REPLACE PROCEDURE sbxtax4.datax_utl_fka_74
   IS

    affected number := 0;
    merchId number;
    esql VARCHAR2(1000);
    errorCode VARCHAR2(1000);
    errorMessage VARCHAR2(1000);

    CURSOR wo_tax_parent IS
    SELECT DISTINCT zone_id, parent_zone_id
    FROM tb_zones z, tb_zone_levels zl
    WHERE z.merchant_id = merchId
    AND tax_parent_Zone_id IS NULL
    AND z.name != 'WORLD'
    AND z.name != 'UNITED STATES'
    AND parent_zone_id != -1
    AND z.zone_level_id = zl.zone_level_id
    AND zl.display_in_short_list = 'N';

begin

    LOCK TABLE tb_zones IN EXCLUSIVE MODE NOWAIT;   -- 05/24/17 Added

    -- 05/24/17, removed all intermediate commits. Now only 1 COMMIT at the end of the procedure to retain the table lock on TB_ZONES

    esql := 'ALTER TRIGGER DT_ZONES DISABLE';
    execute immediate esql;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Disabled DT_ZONES trigger for DATAX_UTL_FKA_74.',-1);
    --COMMIT;

    SELECT merchant_id
    INTO merchId
    FROM tb_merchants
    WHERE name = 'Sabrix US Tax Data';

    UPDATE tb_zones
    SET tax_parent_zone_id = null
    WHERE name = 'WORLD'
    AND merchant_id = merchId
    AND tax_parent_zone_id IS NOT NULL;
    --COMMIT;

    UPDATE tb_zones
    SET tax_parent_zone_id = null
    WHERE merchant_id = merchId
    AND tax_parent_zone_id IS NOT NULL
    AND zone_level_id IN (
        SELECT zone_level_id
        FROM tb_zone_levels
        WHERE display_in_short_list = 'Y'
        );
    affected := affected+SQL%ROWCOUNT;
    --COMMIT;

    UPDATE tb_zones
    SET tax_parent_zone_id = null
    WHERE parent_zone_id = -1
    AND merchant_id = merchId
    AND tax_parent_zone_id IS NOT NULL;
    affected := affected+SQL%ROWCOUNT;
    --COMMIT;


    FOR zone IN wo_tax_parent LOOP
        UPDATE tb_zones z
        SET tax_parent_zone_id = (
            SELECT zone_id
            FROM (
                SELECT z2.zone_id, z2.zone_level_id, MIN(zl.zone_level_id) OVER (PARTITION BY zone.zone_id) lowest_level
                FROM tb_zones z2, tb_zone_levels zl
                WHERE z2.zone_level_id = zl.zone_level_id
                AND zl.display_in_short_list = 'Y'
                AND z2.zone_id IN (
                    SELECT zone_id
                    FROM tb_Zones
                    START WITH zone_id = zone.parent_zone_id
                    CONNECT BY PRIOR parent_zone_id = zone_id
                    )
            )
            WHERE zone_level_id = lowest_level
        )
        WHERE z.zone_id = zone.zone_id;
        affected := affected+SQL%ROWCOUNT;
        --COMMIT;
    END LOOP;



    --COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_UTL_FKA_74 updated '||affected||' rows.',-1);
    --COMMIT;

    esql := 'ALTER TRIGGER DT_ZONES COMPILE';
    execute immediate esql;
    esql := 'ALTER TRIGGER DT_ZONES ENABLE';
    execute immediate esql;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Enabled and compiled DT_ZONES trigger after completion of DATAX_UTL_FKA_74.',-1);
    --COMMIT;

EXCEPTION WHEN OTHERS THEN

    esql := 'ALTER TRIGGER DT_ZONES COMPILE';
    execute immediate esql;
    esql := 'ALTER TRIGGER DT_ZONES ENABLE';
    execute immediate esql;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Enabled and compiled DT_ZONES trigger after completion of DATAX_UTL_FKA_74.',-1);
    --COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('End Procedure...Terminated unnaturally! Error occurred while executing DataCheck tests for DATAX_UTL_FKA_74',-1);
    --COMMIT;
    errorCode := SQLCODE;
    errorMessage := SQLERRM;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES (errorCode||':'||SUBSTR(errorMessage, 1, 993),-1);
    COMMIT;

END; -- Procedure
/