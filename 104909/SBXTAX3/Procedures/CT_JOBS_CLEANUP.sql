CREATE OR REPLACE PROCEDURE sbxtax3.ct_jobs_cleanup
   IS

BEGIN
    FOR j IN (
        SELECT job 
        FROM user_jobs 
        WHERE failures > 2 
        AND what LIKE 'CT%'
        AND what NOT LIKE 'CT_JOBS_CLEANUP') LOOP
        DBMS_JOB.BROKEN(j.job,TRUE);
    END LOOP;

END;
 
 
/