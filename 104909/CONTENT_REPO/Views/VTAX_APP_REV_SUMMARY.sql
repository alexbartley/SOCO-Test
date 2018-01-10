CREATE OR REPLACE FORCE VIEW content_repo.vtax_app_rev_summary (juris_tax_app_rid,juris_tax_app_nkid,change_count,document_count,published_date,is_editable,status) AS
SELECT jtr.rid entity_rid,
            --clo.entity_id,
            jtr.nkid,
            COUNT (DISTINCT clo.primary_key || clo.table_name) change_count,
            COUNT (DISTINCT c.attachment_id) document_count,
            CASE WHEN jtr.status = 2 THEN TO_CHAR (jtr.status_modified_date, 'mm/dd/yyyy HH24:MI:SS') END
               published_date,
            CASE WHEN jtr.next_rid IS NULL THEN 1 ELSE 0 END is_editable,
            jtr.status
       FROM VJURIS_TAX_APP_REV_PK jtr
            JOIN juris_tax_app_chg_logs clo
               ON (clo.rid = jtr.rid) -- AND clo.entity_id = jtr.id)
            JOIN entity_table_map etm
               ON (    etm.table_name = clo.table_name
                   AND etm.logical_entity = 'Taxability')
            LEFT OUTER JOIN juris_tax_chg_cits cc
               ON (cc.juris_tax_chg_log_id = clo.id)
            LEFT OUTER JOIN citations c
               ON (c.id = cc.citation_id)
   GROUP BY jtr.rid,
            --clo.entity_id,
            jtr.nkid,
            jtr.status_modified_date,
            CASE WHEN jtr.status = 2 THEN jtr.status_modified_date END,
            CASE WHEN jtr.next_rid IS NULL THEN 1 ELSE 0 END,
            jtr.status
 
 
 ;