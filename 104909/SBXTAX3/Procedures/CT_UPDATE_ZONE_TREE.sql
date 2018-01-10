CREATE OR REPLACE PROCEDURE sbxtax3.ct_update_zone_tree
   IS
   loggingMessage VARCHAR2(4000);
   affected NUMBER;
   executionDate DATE := sysdate;
   totalAffected NUMBER :=0;
   maxLeaf NUMBER;
   deleteSql VARCHAR2(1000) :='DELETE FROM ct_zone_tree zt WHERE zt.zone_${leafNo}_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM tb_zones WHERE zone_id = zt.zone_${leafNo}_id)';
   emSql VARCHAR2(2000);
BEGIN
    UPDATE ct_zone_tree
    SET creation_Date = '01-Mar-1950'
    WHERE creation_Date IS NULL;

    SELECT MAX(TO_NUMBER(REPLACE(REPLACE(column_name,'ZONE_'),'_ID')))
    INTO maxLeaf
    FROM user_tab_columns
    WHERE column_name like 'ZONE%ID'
    AND column_name not like 'ZONE%LEVEL_ID'
    AND table_name = 'CT_ZONE_TREE';   
    
    DELETE FROM ct_zone_tree zt
    WHERE NOT EXISTS (
        SELECT 1
        FROM tb_zones
        WHERE zone_id = zt.primary_key
        );
    affected := SQL%ROWCOUNT;   
    totalAffected := totalAffected+affected;
    COMMIT;

    
    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
    VALUES ('CT_UPDATE_ZONE_TREE',executionDate,to_char(affected)||' records deleted from CT_ZONE_TREE because they no longer exist in TB_ZONES.');
    COMMIT;
    affected := 0;
    DELETE FROM ct_zone_tree zt
    WHERE EXISTS (
        SELECT 1
        FROM tb_zones z
        WHERE zt.primary_key = z.zone_id
        AND z.last_update_date > zt.creation_date
        );
    affected := SQL%ROWCOUNT;   
    totalAffected := totalAffected+affected;
    COMMIT;
    
    FOR n IN 1..maxLeaf LOOP
        emSql := REPLACE(deleteSql,'${leafNo}',TO_CHAR(n));
        execute immediate emSql;
        affected := affected+SQL%ROWCOUNT;   
        totalAffected := totalAffected+SQL%ROWCOUNT;
        COMMIT;
    END LOOP;
    
    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
    VALUES ('CT_UPDATE_ZONE_TREE',executionDate,to_char(affected)||' records deleted from CT_ZONE_TREE because they were modified in TB_ZONES after being inserted into CT_ZONE_TREE.');
    COMMIT;
    CT_POPULATE_ZONE_TREE();
    CT_UPDATE_ZONE_AUTHORITIES();
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_UPDATE_ZONE_TREE',SYSDATE,loggingMessage);
END; -- Procedure
 
 
/