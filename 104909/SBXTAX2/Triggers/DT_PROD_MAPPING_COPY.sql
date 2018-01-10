CREATE OR REPLACE TRIGGER sbxtax2."DT_PROD_MAPPING_COPY" 
 BEFORE 
 INSERT
 ON sbxtax2.TB_PRODUCT_CROSS_REF
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
DECLARE
    v_prod_cross_ref_id number;
    v_prod_cross_ref_group_id number;
    v_exists number;
    duplicate_mapping EXCEPTION;
    v_from_merchant number;
    v_product_group_id number;
    v_existing_code varchar2(100);
    v_existing_product number;
    
BEGIN
    SELECT COUNT(*)
    INTO v_from_merchant
    FROM tb_merchants
    WHERE product_cross_ref_group_id = :NEW.product_cross_ref_group_id
    AND NAME IN ('QABRAZIL','QAINDIA','Genoa Test','International Test','Global Content','QA Base Line Est','QA Base Line Not Est','India Test','EU Test','QA Base Line Est Not Reg');
    
    IF (v_from_merchant > 0) THEN
    
        SELECT PRODUCT_CROSS_REF_GROUP_ID
        INTO v_prod_cross_ref_group_id
        FROM tb_merchants
        WHERE name = 'QA001';
        
        SELECT product_group_id
        INTO v_product_group_id
        FROM tb_product_categories
        WHERE product_Category_id = :NEW.product_category_id;

        SELECT max(source_product_code), max(product_category_id), max(num_of)
        INTO v_existing_code, v_existing_product, v_exists
        FROM (
            SELECT source_product_code, pc.product_category_id, COUNT(*) num_of
            FROM TB_PRODUCT_CROSS_REF r, tb_product_categories pc
            WHERE PRODUCT_CROSS_REF_GROUP_ID = v_prod_cross_ref_group_id
            AND source_product_code = :NEW.source_product_code
            AND pc.product_Category_id = r.product_Category_id
            AND pc.product_Group_id = v_product_group_id
            GROUP BY source_product_code, pc.product_category_id
            UNION
            SELECT to_char('.'), -1, 0
            FROM dual
        );

        IF (v_exists = 0) THEN

            SELECT MAX(PRODUCT_CROSS_REF_ID)+5
            INTO v_prod_cross_ref_id
            FROM TB_PRODUCT_CROSS_REF;

            INSERT INTO TB_PRODUCT_CROSS_REF(PRODUCT_CROSS_REF_ID,PRODUCT_CROSS_REF_GROUP_ID,PRODUCT_CATEGORY_ID,SOURCE_PRODUCT_CODE,
                INPUT_RECOVERY_TYPE,OUTPUT_RECOVERY_TYPE,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE)
            VALUES (v_prod_cross_ref_id,v_prod_cross_ref_group_id,:NEW.product_category_id,:NEW.source_product_code,:NEW.input_recovery_type,:NEW.output_recovery_type, :NEW.created_by,
                    :NEW.creation_Date, :NEW.last_updated_by, :NEW.last_update_Date);

            UPDATE tb_counters
            SET value = (
                SELECT MAX(PRODUCT_CROSS_REF_ID)
                FROM TB_PRODUCT_CROSS_REF)
            WHERE name = 'TB_PRODUCT_CROSS_REF';
        ELSIF (v_existing_code = :NEW.source_product_code AND v_existing_product = :NEW.product_category_id) THEN
            v_exists := null;--DO NOTHING, if the incoming mapping is exactly the same as one that already exists on QA001, it doesn't need to be copied
        ELSE
            RAISE duplicate_mapping;
        END IF;
    END IF;
    
    EXCEPTION WHEN duplicate_mapping THEN
        raise_application_error(-20001, 'The Product Code already exists in QA001, please enter a different code. Have a nice day!');


END DT_PROD_MAPPING_COPY;
/