CREATE MATERIALIZED VIEW content_repo.mv_tax_relationships ("ID",jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,related_jurisdiction_id,related_jurisdiction_nkid,relationship_type,entered_by,entered_date,start_date,end_date,status,status_modified_date,basis_percent) 
TABLESPACE content_repo
AS select a.* from tax_relationships a join mvjurisdictions b on a.jurisdiction_nkid = b.nkid;