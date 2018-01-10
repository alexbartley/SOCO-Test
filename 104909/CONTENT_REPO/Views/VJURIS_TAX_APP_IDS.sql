CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_app_ids ("ID",nkid) AS
select distinct id, nkid
from juris_tax_applicabilities;