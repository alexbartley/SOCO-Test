CREATE OR REPLACE PROCEDURE sbxtax4."CT_UPDATE_REPORT_QUEUE"
   ( filename IN VARCHAR2, newStatus IN VARCHAR2)
   IS
   loggingMessage VARCHAR2(4000);
BEGIN
    IF newStatus = 'WORKING' THEN

        UPDATE ct_report_exec_history outer
        SET status = newStatus, status_update_date = SYSDATE
        WHERE output_filename = filename
        AND status = 'QUEUED'
        AND queued_date = (
            SELECT MIN(queued_date)
            FROM ct_report_exec_history sub
            WHERE sub.output_filename = outer.output_filename
            AND sub.status = outer.status);
        COMMIT;
    ELSIF newStatus LIKE 'FINISHED%' THEN

        UPDATE ct_report_exec_history outer
        SET status = newStatus, status_update_date = SYSDATE
        WHERE output_filename = filename
        AND status = 'WORKING'
        AND queued_date = (
            SELECT MIN(queued_date)
            FROM ct_report_exec_history sub
            WHERE sub.output_filename = outer.output_filename
            AND sub.status = outer.status);
        COMMIT;
    ELSE
        UPDATE ct_report_exec_history outer
        SET status = newStatus, status_update_date = SYSDATE
        WHERE output_filename = filename
        AND queued_date = (
            SELECT MIN(queued_date)
            FROM ct_report_exec_history sub
            WHERE sub.output_filename = outer.output_filename
            AND sub.status = outer.status);
        COMMIT;
    END IF;

EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_UPDATE_REPORT_QUEUE',SYSDATE,loggingMessage);

END; -- Procedure


 
 
 
/