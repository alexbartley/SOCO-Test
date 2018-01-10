CREATE OR REPLACE FORCE VIEW content_repo.vjuris_ids ("ID",nkid) AS
SELECT DISTINCT id, nkid FROM jurisdictions
 
 
 ;