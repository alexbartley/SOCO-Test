CREATE OR REPLACE TRIGGER sbxtax4."DEL_A_APP_ERRORS"
BEFORE DELETE ON sbxtax4.TB_APP_ERRORS
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
BEGIN
  INSERT INTO A_APP_ERRORS (
ERROR_ID_O,
ERROR_NUM_O,
ERROR_SEVERITY_O,
TITLE_O,
DESCRIPTION_O,
CAUSE_O,
ACTION_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
CATEGORY_O,
MERCHANT_ID_O,
AUTHORITY_ID_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:OLD.ERROR_ID,
:OLD.ERROR_NUM,
:OLD.ERROR_SEVERITY,
:OLD.TITLE,
:OLD.DESCRIPTION,
:OLD.CAUSE,
:OLD.ACTION,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
--:OLD.SYNCHRONIZATION_TIMESTAMP,
:OLD.CATEGORY,
:OLD.MERCHANT_ID,
:OLD.AUTHORITY_ID,
    'DELETED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :OLD.MERCHANT_ID),
    SYSDATE);
END;
/