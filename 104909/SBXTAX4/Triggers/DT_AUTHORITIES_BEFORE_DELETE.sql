CREATE OR REPLACE TRIGGER sbxtax4."DT_AUTHORITIES_BEFORE_DELETE" 
 BEFORE 
 DELETE
 ON sbxtax4.TB_AUTHORITIES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
DECLARE
v_merchant_name VARCHAR2(100);
v_already_shipped NUMBER;
AUTH_CANNOT_BE_DELETED EXCEPTION;
BEGIN
    SELECT m.name
    INTO v_merchant_name
    FROM tb_merchants m
    WHERE m.merchant_id = :OLD.merchant_id;
    
    SELECT NVL(MIN(content_journal_id),0)
    INTO v_already_shipped
    FROM tb_content_journal
    WHERE table_name = 'TB_AUTHORITIES'
    AND primary_key = :old.authority_id
    AND operation = 'A'
    AND operation_date > SYSDATE-21;

    IF (v_already_shipped = 0 AND v_merchant_name IN ('Sabrix Canada Tax Data','Sabrix INTL Tax Data','Sabrix US Tax Data')) THEN
        RAISE AUTH_CANNOT_BE_DELETED;
    ELSE
        v_merchant_name := null;
    END IF;
    EXCEPTION WHEN AUTH_CANNOT_BE_DELETED THEN
    raise_application_error(-20001, 'Authorities cannot be deleted, see your supervisor to have an authority removed.');
END;
/