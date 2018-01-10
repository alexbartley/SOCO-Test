CREATE OR REPLACE FORCE VIEW content_repo.vadmin_ids ("ID",nkid) AS
select distinct id, nkid
from administrators
 
 
 ;