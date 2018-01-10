CREATE OR REPLACE TRIGGER sbxtax.ins_etl_proc_log
BEFORE INSERT
   ON sbxtax.etl_proc_log
   FOR EACH ROW

BEGIN
    :new.id := pk_etl_proc_log.nextval;
    :new.log_time := SYSTIMESTAMP;
END;
/