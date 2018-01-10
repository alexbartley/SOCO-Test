CREATE OR REPLACE FORCE VIEW sbxtax.v_juris_extract_log (nkid,rid,official_name,queued_date,extract_date,transformed,not_transformed,loaded,not_loaded) AS
select j.nkid, el.rid, j.official_name, el.queued_date, el.extract_date, el.transformed, el.not_transformed, el.loaded, el.not_loaded
from crapp_extract.jurisdictions j
join extract_log el on (el.entity = 'JURISDICTION' and el.nkid = j.nkid)
where j.next_rid is null
 
 ;