CREATE OR REPLACE TRIGGER sbxtax."UPD_A_RATES"
AFTER UPDATE OF
    RATE_CODE,
    DESCRIPTION,
    RATE,
    FLAT_FEE,
    CURRENCY_ID,
    UNIT_OF_MEASURE_CODE,
    USE_DEFAULT_QTY,
    MERCHANT_ID,
    AUTHORITY_ID,
    START_DATE,
    END_DATE,
    SPLIT_TYPE,
    SPLIT_AMOUNT_TYPE,
    IS_LOCAL
    ON sbxtax.TB_RATES
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
     WHEN (
(
decode(NEW.RATE_CODE,OLD.RATE_CODE,0,1) +
decode(NEW.DESCRIPTION,OLD.DESCRIPTION,0,1) +
decode(NEW.RATE,OLD.RATE,0,1) +
decode(NEW.FLAT_FEE,OLD.FLAT_FEE,0,1) +
decode(NEW.CURRENCY_ID,OLD.CURRENCY_ID,0,1) +
decode(NEW.UNIT_OF_MEASURE_CODE,OLD.UNIT_OF_MEASURE_CODE,0,1) +
decode(NEW.USE_DEFAULT_QTY,OLD.USE_DEFAULT_QTY,0,1) +
decode(NEW.MERCHANT_ID,OLD.MERCHANT_ID,0,1) +
decode(NEW.AUTHORITY_ID,OLD.AUTHORITY_ID,0,1) +
decode(NEW.START_DATE,OLD.START_DATE,0,1) +
decode(NEW.END_DATE,OLD.END_DATE,0,1) +
decode(NEW.SPLIT_TYPE,OLD.SPLIT_TYPE,0,1) +
decode(NEW.SPLIT_AMOUNT_TYPE,OLD.SPLIT_AMOUNT_TYPE,0,1) +
decode(NEW.IS_LOCAL,OLD.IS_LOCAL,0,1)
) > 0
) BEGIN
  INSERT INTO A_RATES (
    RATE_ID,
    RATE_CODE,
    DESCRIPTION,
    RATE,
    FLAT_FEE,
    CURRENCY_ID,
    UNIT_OF_MEASURE_CODE,
    USE_DEFAULT_QTY,
    MERCHANT_ID,
    AUTHORITY_ID,
    START_DATE,
    END_DATE,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    --SYNCHRONIZATION_TIMESTAMP,
    SPLIT_TYPE,
    SPLIT_AMOUNT_TYPE,
    IS_LOCAL,
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
    :NEW.RATE_ID,
    :NEW.RATE_CODE,
    :NEW.DESCRIPTION,
    :NEW.RATE,
    :NEW.FLAT_FEE,
    :NEW.CURRENCY_ID,
    :NEW.UNIT_OF_MEASURE_CODE,
    :NEW.USE_DEFAULT_QTY,
    :NEW.MERCHANT_ID,
    :NEW.AUTHORITY_ID,
    :NEW.START_DATE,
    :NEW.END_DATE,
    :NEW.CREATED_BY,
    :NEW.CREATION_DATE,
    :NEW.LAST_UPDATED_BY,
    :NEW.LAST_UPDATE_DATE,
    --:NEW.SYNCHRONIZATION_TIMESTAMP,
    :NEW.SPLIT_TYPE,
    :NEW.SPLIT_AMOUNT_TYPE,
    :NEW.IS_LOCAL,
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
    'UPDATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M WHERE M.MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
END;
/