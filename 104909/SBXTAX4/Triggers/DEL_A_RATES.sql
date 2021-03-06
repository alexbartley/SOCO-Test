CREATE OR REPLACE TRIGGER sbxtax4."DEL_A_RATES"
BEFORE DELETE ON sbxtax4.TB_RATES
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
BEGIN
  INSERT INTO A_RATES (
     RATE_ID_O,
    RATE_CODE_O,
    DESCRIPTION_O,
    RATE_O,
    FLAT_FEE_O,
    CURRENCY_ID_O,
    UNIT_OF_MEASURE_CODE_O,
    USE_DEFAULT_QTY_O,
    MERCHANT_ID_O,
    AUTHORITY_ID_O,
    START_DATE_O,
    END_DATE_O,
    CREATED_BY_O,
    CREATION_DATE_O,
    LAST_UPDATED_BY_O,
    LAST_UPDATE_DATE_O,
    --SYNCHRONIZATION_TIMESTAMP_O,
    SPLIT_TYPE_O,
    SPLIT_AMOUNT_TYPE_O,
    IS_LOCAL_O,
    CHANGE_TYPE,
    --CHANGE_VERSION,
    CHANGE_DATE
  ) VALUES (
    :OLD.RATE_ID,
    :OLD.RATE_CODE,
    :OLD.DESCRIPTION,
    :OLD.RATE,
    :OLD.FLAT_FEE,
    :OLD.CURRENCY_ID,
    :OLD.UNIT_OF_MEASURE_CODE,
    :OLD.USE_DEFAULT_QTY,
    :OLD.MERCHANT_ID,
    :OLD.AUTHORITY_ID,
    :OLD.START_DATE,
    :OLD.END_DATE,
    :OLD.CREATED_BY,
    :OLD.CREATION_DATE,
    :OLD.LAST_UPDATED_BY,
    :OLD.LAST_UPDATE_DATE,
    --:OLD.SYNCHRONIZATION_TIMESTAMP,
    :OLD.SPLIT_TYPE,
    :OLD.SPLIT_AMOUNT_TYPE,
    :OLD.IS_LOCAL,
    'DELETED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M WHERE M.MERCHANT_ID = :OLD.MERCHANT_ID),
    SYSDATE);
END;
/