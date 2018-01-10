CREATE OR REPLACE PROCEDURE sbxtax2.ct_product_tree_sort
   IS
   loggingMessage VARCHAR2(4000);
BEGIN

    
    DELETE FROM pt_temp_product_tree_sort;

    INSERT INTO pt_temp_product_Tree_sort (branch_sort, product_Category_id
    ) (
        SELECT LPAD(COUNT(*) OVER (PARTITION BY parent_product_category_id ORDER BY NAME),5,'0') branch_sort, product_category_id
        FROM tb_product_categories pc
    );
    
    DELETE FROM pt_product_tree_sort;
    INSERT INTO pt_product_tree_sort (
        sort_key, primary_key, prodcode, product_group_id, product_name, merchant_id, 
        product_1_name, product_1_id, product_2_name, product_2_id, 
        product_3_name, product_3_id, product_4_name, product_4_id, 
        product_5_name, product_5_id, product_6_name, product_6_id, 
        product_7_name, product_7_id, product_8_name, product_8_id, 
        product_9_name, product_9_id 
    ) (
        SELECT NVL(ts1.branch_sort,'00000')||'.'||
            NVL(ts2.branch_sort,'00000')||'.'||
            NVL(ts3.branch_sort,'00000')||'.'||
            NVL(ts4.branch_sort,'00000')||'.'||
            NVL(ts5.branch_sort,'00000')||'.'||
            NVL(ts6.branch_sort,'00000')||'.'||
            NVL(ts7.branch_sort,'00000')||'.'||
            NVL(ts8.branch_sort,'00000') sort_key, 
            all_prods.*
        FROM (
            SELECT pc.product_category_id, pc.prodcode, pc.product_group_id, pc.name product_name, pt.merchant_id, 
                product_1_name, product_1_id, 
                product_2_name, product_2_id, 
                product_3_name, product_3_id, 
                product_4_name, product_4_id, 
                product_5_name, product_5_id, 
                product_6_name, product_6_id, 
                product_7_name, product_7_id, 
                product_8_name, product_8_id, 
                product_9_name, product_9_id
            FROM tb_product_categories pc, ct_product_tree pt
            WHERE pc.product_category_id = pt.primary_key 
            --AND pc.merchant_id = merchantId
        ) all_prods
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts1 ON (all_prods.product_2_id = ts1.product_category_id)
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts2 ON (all_prods.product_3_id = ts2.product_category_id)
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts3 ON (all_prods.product_4_id = ts3.product_category_id)
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts4 ON (all_prods.product_5_id = ts4.product_category_id)
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts5 ON (all_prods.product_6_id = ts5.product_category_id)
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts6 ON (all_prods.product_7_id = ts6.product_category_id)
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts7 ON (all_prods.product_8_id = ts7.product_category_id)
        LEFT OUTER JOIN pt_temp_product_Tree_sort ts8 ON (all_prods.product_9_id = ts8.product_category_id)
    );
    
    DELETE FROM pt_temp_product_tree_sort;
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_PRODUCT_TREE_SORT',SYSDATE,loggingMessage);

END; -- Procedure
 
 
/