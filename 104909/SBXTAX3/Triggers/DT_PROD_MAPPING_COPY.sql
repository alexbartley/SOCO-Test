CREATE OR REPLACE TRIGGER sbxtax3."DT_PROD_MAPPING_COPY" 
 BEFORE
  INSERT
 ON sbxtax3.tb_product_cross_ref
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    v_prod_cross_ref_id number;
    v_prod_cross_ref_group_id number;
    v_exists number;
    duplicate_mapping EXCEPTION;
    v_from_merchant number;
    
BEGIN
    SELECT COUNT(*)
    INTO v_from_merchant
    FROM tb_merchants
    WHERE product_cross_ref_group_id = :NEW.product_cross_ref_group_id
    AND NAME IN ('Canada Test');
    
    IF (v_from_merchant > 0) THEN
    
        SELECT PRODUCT_CROSS_REF_GROUP_ID
        INTO v_prod_cross_ref_group_id
        FROM tb_merchants
        WHERE name = 'QA001';

        SELECT COUNT(*)
        INTO v_exists
        FROM TB_PRODUCT_CROSS_REF
        WHERE PRODUCT_CROSS_REF_GROUP_ID = v_prod_cross_ref_group_id
        AND source_product_code = :NEW.source_product_code;

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
        ELSE
            RAISE duplicate_mapping;
        END IF;
    END IF;
    
    EXCEPTION WHEN duplicate_mapping THEN
        raise_application_error(-20001, 'The Product Code already exists in QA001, please enter a different code. Have a nice day!');


END DT_PROD_MAPPING_COPY;
/