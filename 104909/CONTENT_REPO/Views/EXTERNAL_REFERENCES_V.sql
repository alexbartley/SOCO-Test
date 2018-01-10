CREATE OR REPLACE FORCE VIEW content_repo.external_references_v ("ID",chng_id,entity_type,ref_system,ref_id,ext_link,entered_date,system_name,system_descr) AS
(
 Select eref.id, eref.chng_id, eref.entity_type, eref.ref_system, eref.ref_id, eref.ext_link,
 eref.entered_date,
 esys.system_name,
 esys.system_descr
 FROM
 external_references eref
 JOIN external_reference_system esys ON (esys.id = eref.ref_system)
)
 
 
 ;