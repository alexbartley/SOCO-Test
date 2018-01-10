CREATE OR REPLACE TRIGGER sbxtax4."BLOCK_MANUAL_ENTRY_PRODS"
 BEFORE
  INSERT OR UPDATE
 ON sbxtax4.tb_product_categories
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
declare
    PRODUCT_ENTRY_DISALLOWED exception;
	PRODUCT_UPDATE_DISALLOWED exception;
    v_merchant_name VARCHAR2(200);
begin
    SELECT m.name
    INTO v_merchant_name
    FROM tb_merchants m
    WHERE m.merchant_id = :NEW.merchant_id;
	
	IF INSERTING THEN
    
		IF (:new.created_by != -1703 and v_merchant_name like 'Sabrix%Tax Data') THEN
			RAISE PRODUCT_ENTRY_DISALLOWED;

		END IF;
	
	ELSIF UPDATING THEN
		IF (:new.last_updated_by != -1703 and v_merchant_name like 'Sabrix%Tax Data') THEN
			RAISE PRODUCT_UPDATE_DISALLOWED;

		END IF;
	
	END IF;
    EXCEPTION 
	WHEN PRODUCT_ENTRY_DISALLOWED THEN
        raise_application_error(-20001, 'Products must not be manually created in Sabrix US Tax Data, please use the ETL.');
	WHEN PRODUCT_UPDATE_DISALLOWED THEN
        raise_application_error(-20002, 'Products must not be manually updated in Sabrix US Tax Data, please use the ETL.');

end;
/