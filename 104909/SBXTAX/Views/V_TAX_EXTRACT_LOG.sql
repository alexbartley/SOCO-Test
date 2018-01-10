CREATE OR REPLACE FORCE VIEW sbxtax.v_tax_extract_log (nkid,rid,official_name,reference_code,queued_date,extract_date,transformed,not_transformed,loaded,not_loaded) AS
select jti.nkid, el.rid, j.official_name, jti.reference_code, el.queued_date, el.extract_date, el.transformed, el.not_transformed, el.loaded, el.not_loaded
from crapp_extract.jurisdictions j
join crapp_extract.juris_tax_impositions jti on (jti.jurisdiction_nkid = j.nkid)
join extract_log el on (el.entity = 'TAX' and el.nkid = jti.nkid)
where j.next_rid is null
and jti.next_rid is null
 
 ;