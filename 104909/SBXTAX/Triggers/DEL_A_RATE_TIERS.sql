CREATE OR REPLACE TRIGGER sbxtax."DEL_A_RATE_TIERS"
BEFORE DELETE ON sbxtax.TB_RATE_TIERS
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
BEGIN
  INSERT INTO A_RATE_TIERS (
    RATE_TIER_ID_O,
    RATE_ID_O,
    RATE_O,
    FLAT_FEE_O,
    AMOUNT_LOW_O,
    AMOUNT_HIGH_O,
    RATE_CODE_O,
    CREATED_BY_O,
    CREATION_DATE_O,
    LAST_UPDATED_BY_O,
    LAST_UPDATE_DATE_O,
    --SYNCHRONIZATION_TIMESTAMP_O,
    CHANGE_TYPE,
    --CHANGE_VERSION,
    CHANGE_DATE
  ) VALUES (
    :OLD.RATE_TIER_ID,
    :OLD.RATE_ID,
    :OLD.RATE,
    :OLD.FLAT_FEE,
    :OLD.AMOUNT_LOW,
    :OLD.AMOUNT_HIGH,
    :OLD.RATE_CODE,
    :OLD.CREATED_BY,
    :OLD.CREATION_DATE,
    :OLD.LAST_UPDATED_BY,
    :OLD.LAST_UPDATE_DATE,
    --:OLD.SYNCHRONIZATION_TIMESTAMP,
    'DELETED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_RATES R WHERE R.RATE_ID = :OLD.RATE_ID AND R.MERCHANT_ID = M.MERCHANT_ID),
    SYSDATE);
END;
/