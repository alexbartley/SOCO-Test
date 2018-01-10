CREATE OR REPLACE PROCEDURE sbxtax."CT_UPDATE_PRODUCT_TREE"
   IS
   loggingMessage VARCHAR2(4000);
   affected       NUMBER;
   totalAffected  NUMBER := 0;
   executionDate  DATE := SYSDATE;
   maxLeaf        NUMBER;
   deleteSql      VARCHAR2(1000) :='DELETE FROM ct_product_tree pt WHERE pt.product_${leafNo}_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM tb_product_categories WHERE product_Category_id = pt.product_${leafNo}_id)';
   deleteNameSql  VARCHAR2(1000) :='DELETE FROM ct_product_tree pt WHERE pt.product_${leafNo}_name IS NOT NULL AND NOT EXISTS (SELECT 1 FROM tb_product_categories WHERE TRIM(name) = TRIM(pt.product_${leafNo}_name))';
   emSql          VARCHAR2(2000);
BEGIN
    UPDATE ct_product_tree
        SET creation_date = '01-Mar-1950'
    WHERE creation_date IS NULL;

    SELECT MAX(TO_NUMBER(REPLACE(REPLACE(column_name,'PRODUCT_'),'_ID')))
    INTO  maxLeaf
    FROM  user_tab_columns
    WHERE column_name LIKE 'PRODUCT%ID'
          AND column_name NOT LIKE 'PRODUCT_GROUP_ID'
          AND table_name = 'CT_PRODUCT_TREE';

    DELETE FROM ct_product_tree pt
    WHERE NOT EXISTS (
                      SELECT 1
                      FROM  tb_product_categories
                      WHERE product_category_id = pt.primary_key
                     );
    affected := SQL%ROWCOUNT;
    totalAffected := totalAffected+affected;
    COMMIT;

    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
           VALUES ('CT_UPDATE_PRODUCT_TREE',executionDate,TO_CHAR(affected)||' records deleted from CT_PRODUCT_TREE because they no longer exist in TB_PRODUCT_CATEGORIES.');
    COMMIT;
    affected := 0;
    DELETE FROM ct_product_tree pt
    WHERE EXISTS (
                  SELECT 1
                  FROM  tb_product_categories pc
                  WHERE pt.primary_key = pc.product_category_id
                        AND pc.last_update_date > pt.creation_date
                 );
    affected := SQL%ROWCOUNT;
    totalAffected := totalAffected+affected;
    COMMIT;

    FOR n IN 1..maxLeaf LOOP
        emSql := REPLACE(deleteSql,'${leafNo}',TO_CHAR(n));
        EXECUTE IMMEDIATE emSql;
        affected := affected+SQL%ROWCOUNT;
        totalAffected := totalAffected+SQL%ROWCOUNT;
        COMMIT;
    END LOOP;

    -- crapp-3325 - Change in Product Name --
    FOR n IN 1..maxLeaf LOOP
        emSql := REPLACE(deleteNameSql,'${leafNo}',TO_CHAR(n));
        EXECUTE IMMEDIATE emSql;
        affected := affected+SQL%ROWCOUNT;
        totalAffected := totalAffected+SQL%ROWCOUNT;
        COMMIT;
    END LOOP;

    INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
           VALUES ('CT_UPDATE_PRODUCT_TREE',executionDate,TO_CHAR(affected)||' records deleted from CT_PRODUCT_TREE because they were modified in TB_PRODUCT_CATEGORIES after being inserted into CT_PRODUCT_TREE.');
    COMMIT;

    CT_POPULATE_PRODUCT_TREE(affected);
    totalAffected := totalAffected+affected;
    IF (totalAffected > 0) THEN
        CT_PRODUCT_TREE_SORT();
    END IF;
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message) VALUES ('CT_UPDATE_PRODUCT_TREE',SYSDATE,loggingMessage);
END; -- Procedure
/