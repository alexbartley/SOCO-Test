CREATE OR REPLACE FORCE VIEW sbxtax4.v_taxability_extract_log (nkid,rid,official_name,reference_code,queued_date,extract_date,transformed,not_transformed,loaded,not_loaded) AS
select jta.nkid, el.rid, j.official_name, jta.reference_code, el.queued_date, el.extract_date, el.transformed, el.not_transformed, el.loaded, el.not_loaded
from crapp_extract.jurisdictions j
join crapp_extract.juris_tax_applicabilities jta on (jta.jurisdiction_nkid = j.nkid)
join extract_log el on (el.entity = 'TAXABILITY' and el.nkid = jta.nkid)
where j.next_rid is null
and jta.next_rid is null
 
 ;