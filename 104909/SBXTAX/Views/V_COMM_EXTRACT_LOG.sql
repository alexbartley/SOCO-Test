CREATE OR REPLACE FORCE VIEW sbxtax.v_comm_extract_log (nkid,rid,"NAME",commodity_code,queued_date,extract_date,transformed,not_transformed,loaded,not_loaded) AS
select cg.nkid, el.rid, cg.name, cg.commodity_code, el.queued_date, el.extract_date, el.transformed, el.not_transformed, el.loaded, el.not_loaded
from crapp_extract.commodities cg
join extract_log el on (el.entity = 'COMMODITY' and el.nkid = cg.nkid)
where cg.next_rid is null
 
 ;