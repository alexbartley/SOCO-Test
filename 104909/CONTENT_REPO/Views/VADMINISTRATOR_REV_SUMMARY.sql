CREATE OR REPLACE FORCE VIEW content_repo.vadministrator_rev_summary (administrator_rid,administrator_nkid,change_count,document_count,published_date,is_editable,status) AS
SELECT ar.id entity_rid,
            ar.nkid,
            COUNT (DISTINCT clo.primary_key || clo.table_name) change_count,
            COUNT (DISTINCT c.attachment_id) document_count,
            CASE
               WHEN ar.status = 2
               THEN
                  TO_CHAR (ar.status_modified_date, 'mm/dd/yyyy HH24:MI:SS')
            END
               published_date,
            CASE WHEN ar.next_rid IS NULL THEN 1 ELSE 0 END is_editable,
            ar.status
       FROM administrator_revisions ar
            LEFT OUTER JOIN admin_chg_logs clo
               ON (clo.rid = ar.id)
            LEFT OUTER JOIN entity_table_map etm
               ON (    etm.table_name = clo.table_name
                   AND etm.logical_entity = 'Administrator')
            LEFT OUTER JOIN admin_chg_cits cc
               ON (cc.admin_chg_log_id = clo.id)
            LEFT OUTER JOIN citations c
               ON (c.id = cc.citation_id)
   GROUP BY ar.id,
            ar.nkid,
            ar.status_modified_date,
            CASE WHEN ar.status = 2 THEN ar.status_modified_date END,
            CASE WHEN ar.next_rid IS NULL THEN 1 ELSE 0 END,
            ar.status
 
 
 ;