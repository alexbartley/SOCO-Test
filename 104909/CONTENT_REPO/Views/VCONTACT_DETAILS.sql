CREATE OR REPLACE FORCE VIEW content_repo.vcontact_details ("ID",research_source_id,contact_usage_id,contact_usage_type_id,usage_order,contact_method_id,contact_method,contact_reason_id,contact_reason,contact_details,contact_notes,contact_language_id,status) AS
SELECT rsc.id,
          rsc.research_source_id,
          cu.id contact_usage_id,
          cu.contact_usage_type_id,
          cu.usage_order,
          rsc.contact_type_id contact_method_id,
          ct.name contact_method,
          cut.id contact_reason_id,
          cut.name contact_reason,
          rsc.contact_details,
          rsc.contact_notes,
          rsc.language_id contact_language_id,
          rsc.status
     FROM research_source_contacts rsc
          JOIN contact_types ct
             ON (ct.id = rsc.contact_type_id)
          JOIN contact_usages cu
             ON (rsc.id = cu.research_source_contact_id)
          JOIN contact_usage_types cut
             ON (cut.id = cu.contact_usage_type_id)
 
 
 ;