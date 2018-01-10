CREATE MATERIALIZED VIEW content_repo.mv_tax_ref_rate_code ("ID",nkid,reference_code) 
TABLESPACE content_repo
AS select a.id, a.nkid, a.reference_code from juris_tax_impositions a, mvtax_definitions2 b 
where a.id = b.ref_juris_tax_id;