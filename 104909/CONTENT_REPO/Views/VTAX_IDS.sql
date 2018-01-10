CREATE OR REPLACE FORCE VIEW content_repo.vtax_ids ("ID",nkid) AS
select distinct id, nkid
from juris_tax_impositions
 
 
 ;