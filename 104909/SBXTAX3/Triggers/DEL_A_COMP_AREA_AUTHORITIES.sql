CREATE OR REPLACE TRIGGER sbxtax3."DEL_A_COMP_AREA_AUTHORITIES" 
BEFORE DELETE ON sbxtax3.TB_COMP_AREA_AUTHORITIES
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN

      INSERT INTO A_COMP_AREA_AUTHORITIES (
AUTHORITY_ID_O,
COMPLIANCE_AREA_AUTH_ID_O,
COMPLIANCE_AREA_ID_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
    --SYNCHRONIZATION_TIMESTAMP_O,
    CHANGE_TYPE,
    --CHANGE_VERSION,
    CHANGE_DATE
      ) VALUES (
 :OLD.AUTHORITY_ID,
:OLD.COMPLIANCE_AREA_AUTH_ID,
:OLD.COMPLIANCE_AREA_ID,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
    --:OLD.SYNCHRONIZATION_TIMESTAMP,
        'DELETED',
        --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_AUTHORITIES A WHERE A.AUTHORITY_ID = :OLD.AUTHORITY_ID AND M.MERCHANT_ID = A.MERCHANT_ID),
        SYSDATE);

END;
/