CREATE OR REPLACE FORCE VIEW content_repo.vtax_outline_ids ("ID",nkid) AS
SELECT DISTINCT id, nkid FROM tax_outlines
 
 
 ;