CREATE OR REPLACE TRIGGER sbxtax2."DEL_A_PRODUCT_CATEGORIES" 
BEFORE DELETE ON sbxtax2.TB_PRODUCT_CATEGORIES 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  INSERT INTO A_PRODUCT_CATEGORIES (
PRODUCT_CATEGORY_ID_O,
PRODUCT_GROUP_ID_O,
NAME_O,
DESCRIPTION_O,
NOTC_O,
PARENT_PRODUCT_CATEGORY_ID_O,
MERCHANT_ID_O,
PRODCODE_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:OLD.PRODUCT_CATEGORY_ID,
:OLD.PRODUCT_GROUP_ID,
:OLD.NAME,
:OLD.DESCRIPTION,
:OLD.NOTC,
:OLD.PARENT_PRODUCT_CATEGORY_ID,
:OLD.MERCHANT_ID,
:OLD.PRODCODE,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
--:OLD.SYNCHRONIZATION_TIMESTAMP,
    'DELETED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :OLD.MERCHANT_ID),
    SYSDATE);
END;
/