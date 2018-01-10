CREATE MATERIALIZED VIEW content_repo.mv_tax_relationship_juris (nkid,official_name) 
TABLESPACE content_repo
AS select nkid, official_name from jurisdictions a where status = 2
and rid in ( select max(rid) from jurisdictions b where status = 2 and b.nkid = a.nkid );