  CREATE OR REPLACE FORCE EDITIONABLE VIEW "CONTENT_REPO"."VJURIS_ERROR_MESSAGES" ("ID", "NKID", "RID", "NEXT_RID", "JURIS_ID", "JURIS_NKID", "JURIS_RID", "JURIS_NEXT_RID", "SEVERITY_ID", "SEVERITY_DESCRIPTION", "ERROR_MSG", "MSG_DESCRIPTION", "STATUS", "STATUS_MODIFIED_DATE", "ENTERED_BY", "ENTERED_DATE", "START_DATE", "END_DATE") AS
  SELECT jm.id,
          jm.nkid,
          jm.rid,
          jm.next_rid,
          ji.id juris_id,
          ji.nkid juris_nkid,
          r.id juris_entity_rid,
          r.next_rid,          
		      jm.severity_id,
          jsl.severity_description,
          jm.error_msg,
          jm.description,
          jm.status,
          jm.status_modified_date,
          jm.entered_by,
          jm.entered_date,
          jm.start_date,
          jm.end_date
     FROM juris_error_messages jm
        JOIN vjuris_ids ji ON (
            ji.id = jm.jurisdiction_id
        )
        JOIN jurisdiction_revisions r ON (
            r.nkid = ji.nkid
            and rev_join(jm.rid,r.id,COALESCE(jm.next_rid,99999999)) = 1
            )
          JOIN JURIS_MSG_SEVERITY_LOOKUPS jsl
             ON (jm.severity_id = jsl.severity_id);