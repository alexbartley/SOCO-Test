CREATE OR REPLACE PROCEDURE sbxtax3.ct_populate_zone_tree
   IS
   loggingMessage VARCHAR2(4000);
   maxLeaf NUMBER;
   esql VARCHAR2(1000);
   moreCount NUMBER := 1;
   currLevel NUMBER := 1;
   lChar VARCHAR2(1);
   pChar VARCHAR2(1);
   selectColumns VARCHAR2(1000) := 'z.zone_id, z.name, zone_level_id, sysdate creation_date, z.zone_id primary_key, z.merchant_id, to_char(z.tax_parent_zone_id) tax_parent_zone, z.eu_zone_as_of_date, z.code_2char, z.code_3char, z.code_iso, z.code_fips, z.reverse_flag, z.terminator_flag, z.default_flag, z.range_min, z.range_max, z.eu_exit_date, z.gcc_as_of_date, z.gcc_exit_date ';
   insertColumns VARCHAR2(1000) := 'zone_1_id, zone_1_name, zone_1_level_id,creation_date, primary_key, merchant_id, tax_parent_zone, eu_zone_as_of_date, code_2char, code_3char, code_iso, code_fips, reverse_flag, terminator_flag, default_flag, range_min, range_max, eu_exit_date, gcc_as_of_date, gcc_exit_date ';
   insertSql VARCHAR2(4000);
   executionDate DATE := sysdate;
   affected NUMBER;
BEGIN
    SELECT MAX(TO_NUMBER(REPLACE(REPLACE(column_name,'ZONE_'),'_ID')))
    INTO maxLeaf
    FROM user_tab_columns
    WHERE column_name like 'ZONE%ID'
    AND column_name not like 'ZONE_%LEVEL_ID'
    AND table_name = 'CT_ZONE_TREE';


   lChar := to_Char(currLevel);
   insertSql := 'INSERT INTO ct_zone_tree ('||insertColumns||') (SELECT '||selectColumns||
    ' FROM tb_Zones z '||
    'WHERE parent_zone_id = -1 '||
    'AND NOT EXISTS (SELECT 1 FROM ct_Zone_Tree WHERE primary_key = z.zone_id))';
   execute immediate insertSql;-- returning into affected;
   affected := SQL%ROWCOUNT;
   COMMIT;

   INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
   VALUES ('CT_POPULATE_ZONE_TREE',executionDate,to_char(affected)||' inserted to CT_ZONE_TREE @ level '||lChar||'.');
   COMMIT;

    SELECT COUNT(*)
    INTO moreCount
    FROM tb_zones z, ct_zone_tree zt
    WHERE parent_zone_id = zt.primary_key
    AND NOT EXISTS (
        SELECT 1
        FROM ct_zone_tree
        WHERE z.zone_id = primary_key
        );
    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
    VALUES ('CT_POPULATE_ZONE_TREE',executionDate,to_char(moreCount)||' more to insert into CT_ZONE_TREE.');
    COMMIT;

   WHILE (moreCount > 0) LOOP
        pChar := lChar;
        currLevel := currLevel+1;
        lChar := to_char(currLevel);
        IF currLevel > maxLeaf THEN
            esql := 'ALTER TABLE CT_ZONE_TREE ADD (ZONE_'||lChar||'_NAME VARCHAR2(250), ZONE_'||lChar||'_ID NUMBER, ZONE_'||lChar||'_LEVEL_ID NUMBER)';
            execute immediate esql;
            maxLeaf := maxLeaf+1;
            INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
            VALUES ('CT_POPULATE_ZONE_TREE',executionDate,'Leaf added to CT_ZONE_TREE.');
            COMMIT;
        END IF;

        selectColumns := selectColumns||', zone_'||pChar||'_name, zone_'||pChar||'_id, zone_'||pChar||'_level_id  ';
        insertColumns := replace(insertColumns,pChar||'_',lChar||'_');
        insertColumns := insertColumns||', zone_'||pChar||'_name, zone_'||pChar||'_id, zone_'||pChar||'_level_id  ';
        insertSql := 'INSERT INTO ct_zone_tree ('||insertColumns||') (SELECT '||selectColumns||
            ' FROM tb_zones z, ct_zone_tree zt '||
            'WHERE z.parent_Zone_id = NVL(zt.zone_'||pChar||'_id,-2222) '||
            'AND zt.zone_'||lChar||'_id IS NULL '||
            'AND NOT EXISTS (SELECT 1 FROM ct_zone_tree zt2 WHERE zt2.primary_key = z.zone_id))';
        execute immediate insertSql;-- returning into affected;
        affected := SQL%ROWCOUNT;
        COMMIT;
        INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
        VALUES ('CT_POPULATE_ZONE_TREE',executionDate,to_char(affected)||' inserted to CT_ZONE_TREE @ level '||lChar||'.');
        COMMIT;
        SELECT COUNT(*)
        INTO moreCount
        FROM tb_zones z, ct_zone_tree zt
        WHERE parent_zone_id = zt.primary_key
        AND NOT EXISTS (
            SELECT 1
            FROM ct_zone_tree
            WHERE z.zone_id = primary_key
            );
        INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
        VALUES ('CT_POPULATE_ZONE_TREE',executionDate,to_char(moreCount)||' more to insert into CT_ZONE_TREE.');
        COMMIT;
   END LOOP;
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_POPULATE_ZONE_TREE',SYSDATE,loggingMessage);
END; -- Procedure
/