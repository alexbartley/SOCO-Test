CREATE OR REPLACE TRIGGER sbxtax2."INS_A_AUTHORITIES" 
AFTER INSERT ON sbxtax2.TB_AUTHORITIES 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  INSERT INTO A_AUTHORITIES (
    AUTHORITY_ID,
    PRODUCT_GROUP_ID,
    NAME,
    UUID,
    INVOICE_DESCRIPTION,
    DESCRIPTION,
    MERCHANT_ID,
    REGION_CODE,
    REGISTRATION_MASK,
    SIMPLE_REGISTRATION_MASK,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    --SYNCHRONIZATION_TIMESTAMP,
    ADMIN_ZONE_LEVEL_ID,
    EFFECTIVE_ZONE_LEVEL_ID,
    AUTHORITY_TYPE_ID,
    LOCATION_CODE,
    DISTANCE_SALES_THRESHOLD,
    IS_TEMPLATE,
    IS_CUSTOM_AUTHORITY,
    ERP_TAX_CODE,
    CONTENT_TYPE,
    UNIT_OF_MEASURE_CODE,
    OFFICIAL_NAME,
    AUTHORITY_CATEGORY,
    CHANGE_TYPE,
    --CHANGE_VERSION,
    CHANGE_DATE
  ) VALUES (
    :NEW.AUTHORITY_ID,
    :NEW.PRODUCT_GROUP_ID,
    :NEW.NAME,
    :NEW.UUID,
    :NEW.INVOICE_DESCRIPTION,
    :NEW.DESCRIPTION,
    :NEW.MERCHANT_ID,
    :NEW.REGION_CODE,
    :NEW.REGISTRATION_MASK,
    :NEW.SIMPLE_REGISTRATION_MASK,
    :NEW.CREATED_BY,
    :NEW.CREATION_DATE,
    :NEW.LAST_UPDATED_BY,
    :NEW.LAST_UPDATE_DATE,
    --:NEW.SYNCHRONIZATION_TIMESTAMP,
    :NEW.ADMIN_ZONE_LEVEL_ID,
    :NEW.EFFECTIVE_ZONE_LEVEL_ID,
    :NEW.AUTHORITY_TYPE_ID,
    :NEW.LOCATION_CODE,
    :NEW.DISTANCE_SALES_THRESHOLD,
    :NEW.IS_TEMPLATE,
    :NEW.IS_CUSTOM_AUTHORITY,
    :NEW.ERP_TAX_CODE,
    :NEW.CONTENT_TYPE,
    :NEW.UNIT_OF_MEASURE_CODE,
    :NEW.OFFICIAL_NAME,
    :NEW.AUTHORITY_CATEGORY,
    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
END;
/