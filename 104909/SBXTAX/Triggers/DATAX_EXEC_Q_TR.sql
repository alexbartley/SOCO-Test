CREATE OR REPLACE TRIGGER sbxtax."DATAX_EXEC_Q_TR" 
 BEFORE
  INSERT
 ON sbxtax.datax_execution_queue
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT datax_exec_q_seq.NEXTVAL INTO :new.execution_queue_id FROM dual;
  END;
/