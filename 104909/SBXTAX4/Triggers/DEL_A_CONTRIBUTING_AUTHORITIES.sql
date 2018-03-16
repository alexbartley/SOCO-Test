CREATE OR REPLACE TRIGGER sbxtax4."DEL_A_CONTRIBUTING_AUTHORITIES"
BEFORE DELETE ON sbxtax4.TB_CONTRIBUTING_AUTHORITIES
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
BEGIN
  INSERT INTO A_CONTRIBUTING_AUTHORITIES (
CONTRIBUTING_AUTHORITY_ID_O,
MERCHANT_ID_O,
AUTHORITY_ID_O,
THIS_AUTHORITY_ID_O,
BASIS_PERCENT_O,
START_DATE_O,
END_DATE_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:OLD.CONTRIBUTING_AUTHORITY_ID,
:OLD.MERCHANT_ID,
:OLD.AUTHORITY_ID,
:OLD.THIS_AUTHORITY_ID,
:OLD.BASIS_PERCENT,
:OLD.START_DATE,
:OLD.END_DATE,
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