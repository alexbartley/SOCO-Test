CREATE OR REPLACE PROCEDURE sbxtax3."CT_POPULATE_PRODUCT_TREE" (rowsAffected OUT NUMBER)
   IS
   loggingMessage VARCHAR2(4000);
   maxLeaf        NUMBER;
   esql           VARCHAR2(2000);
   moreCount      NUMBER := 1;
   currLevel      NUMBER := 1;
   lChar          VARCHAR2(2);
   pChar          VARCHAR2(2);
   selectColumns  VARCHAR2(2000) := 'pc.product_category_id, pc.name, sysdate creation_date, pc.product_category_id primary_key, pc.merchant_id, pc.product_group_id ';
   insertColumns  VARCHAR2(2000) := 'product_1_id, product_1_name, creation_date, primary_key, merchant_id, product_group_id ';
   insertSql      VARCHAR2(2000);
   executionDate  DATE := SYSDATE;
   affected       NUMBER;
   tdpId          NUMBER;
BEGIN
    rowsAffected := 0;
    SELECT MAX(TO_NUMBER(REPLACE(REPLACE(column_name,'PRODUCT_'),'_ID')))
    INTO  maxLeaf
    FROM  user_tab_columns
    WHERE column_name LIKE 'PRODUCT%ID'
          AND column_name NOT LIKE 'PRODUCT_GROUP_ID'
          AND table_name = 'CT_PRODUCT_TREE';


    lChar := TO_CHAR(currLevel);
    insertSql := 'INSERT INTO ct_product_tree ('||insertColumns||') (SELECT DISTINCT '||selectColumns||      -- crapp-3325, added DISTINCT
                 'FROM tb_product_categories pc, tb_merchants m '||
                 'WHERE pc.merchant_id = m.merchant_id '||
                 'AND NVL(m.is_content_provider,''N'') = ''Y'' '||
                 'AND pc.parent_product_category_id IS NULL '||
                 'AND NOT EXISTS (SELECT 1 FROM ct_product_tree WHERE primary_key = pc.product_Category_id))';
    EXECUTE IMMEDIATE insertSql;-- returning into affected;
    affected := SQL%ROWCOUNT;
    rowsAffected := rowsAffected+affected;
    COMMIT;

    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
           VALUES ('CT_POPULATE_PRODUCT_TREE',executionDate,TO_CHAR(affected)||' inserted to CT_PRODUCT_TREE @ level '||lChar||'.');
    COMMIT;

    SELECT COUNT(*)
    INTO  moreCount
    FROM  tb_product_categories pc, ct_product_tree pt
    WHERE parent_product_category_id = pt.primary_key
          AND NOT EXISTS (
                          SELECT 1
                          FROM  ct_product_tree
                          WHERE pc.product_category_id = primary_key
                         );
    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
           VALUES ('CT_POPULATE_PRODUCT_TREE',executionDate,TO_CHAR(moreCount)||' more to insert into CT_PRODUCT_TREE.');
    COMMIT;

    WHILE (moreCount > 0) LOOP
        pChar := lChar;
        currLevel := currLevel+1;
        lChar := TO_CHAR(currLevel);
        IF currLevel > maxLeaf THEN
            esql := 'ALTER TABLE CT_PRODUCT_TREE ADD (PRODUCT_'||lChar||'_NAME VARCHAR2(250), PRODUCT_'||lChar||'_ID NUMBER)';
            EXECUTE IMMEDIATE esql;
            maxLeaf := maxLeaf+1;
            INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
                   VALUES ('CT_POPULATE_PRODUCT_TREE',executionDate,'Leaf added to CT_PRODUCT_TREE.');
            COMMIT;
        END IF;

        selectColumns := selectColumns||', product_'||pChar||'_name, product_'||pChar||'_id ';
        insertColumns := REPLACE(insertColumns,pChar,lChar);
        insertColumns := insertColumns||', product_'||pChar||'_name, product_'||pChar||'_id ';
        insertSql := 'INSERT INTO ct_product_tree ('||insertColumns||') (SELECT DISTINCT '||selectColumns||         -- crapp-3325, added DISTINCT
                      'FROM tb_product_categories pc, ct_product_tree pt '||
                      'WHERE NVL(pc.parent_product_category_id,-1) = NVL(pt.product_'||pChar||'_id, -2222) '||
                      'AND pt.product_'||lChar||'_id IS NULL '||
                      'AND NOT EXISTS (SELECT 1 FROM ct_product_tree pt2 WHERE pt2.primary_key = pc.product_Category_id))';
        EXECUTE IMMEDIATE insertSql;-- returning into affected;
        affected := SQL%ROWCOUNT;
        rowsAffected := rowsAffected+affected;
        COMMIT;

        INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
               VALUES ('CT_POPULATE_PRODUCT_TREE',executionDate,TO_CHAR(affected)||' inserted to CT_PRODUCT_TREE @ level '||lChar||'.');
        COMMIT;

        SELECT COUNT(*)
        INTO  moreCount
        FROM  tb_product_categories pc, ct_product_tree pt
        WHERE parent_product_category_id = pt.primary_key
              AND NOT EXISTS (
                              SELECT 1
                              FROM  ct_product_tree
                              WHERE pc.product_category_id = primary_key
                             );
        INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
               VALUES ('CT_POPULATE_PRODUCT_TREE',executionDate,TO_CHAR(moreCount)||' more to insert into CT_PRODUCT_TREE.');
        COMMIT;
    END LOOP;

EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message) VALUES ('CT_POPULATE_PRODUCT_TREE',SYSDATE,loggingMessage);
END; -- Procedure
/