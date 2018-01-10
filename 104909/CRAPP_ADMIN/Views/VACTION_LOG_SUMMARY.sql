CREATE OR REPLACE FORCE VIEW crapp_admin.vaction_log_summary (process_id,message,referrer,start_time,end_time,entered_by,status) AS
select process_id, '{'||replace(message, '"}"', '"},"')  ||'}' message, referrer, start_time, end_time, entered_by, status from (
SELECT process_id, RTRIM(
  XMLCAST(
    XMLAGG(
      XMLELEMENT(e, '"'||rownum||'":'||TRIM(parameters) ) order by rownum 
    ) 
    AS CLOB
  ) 
, CHR(10)
) 
 AS MESSAGE,referrer,
MIN(action_start) start_time, MAX(action_end) end_time, MAX(entered_by) entered_by, MAX(status) status
FROM crapp_admin.action_log WHERE process_id >= 0 GROUP BY process_id, referrer
);