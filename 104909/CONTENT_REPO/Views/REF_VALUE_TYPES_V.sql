CREATE OR REPLACE FORCE VIEW content_repo.ref_value_types_v (value_type,type_source) AS
select name, source
from ref_value_types
 
 
 ;