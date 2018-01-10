CREATE OR REPLACE FORCE VIEW content_repo.vcommodity_ids ("ID",nkid) AS
SELECT DISTINCT id, nkid FROM commodities
 
 
 ;