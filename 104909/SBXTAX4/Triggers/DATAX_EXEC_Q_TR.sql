CREATE OR REPLACE TRIGGER sbxtax4."DATAX_EXEC_Q_TR" 
 BEFORE
  INSERT
 ON sbxtax4.datax_execution_queue
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT datax_exec_q_seq.NEXTVAL INTO :new.execution_queue_id FROM dual;
  END;
/