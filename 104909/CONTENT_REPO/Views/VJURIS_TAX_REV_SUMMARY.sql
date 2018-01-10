CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_rev_summary (jurisdiction_tax_rid,jurisdiction_tax_nkid,change_count,document_count,published_date,is_editable,status) AS
SELECT jtr.rid entity_rid,
            --clo.entity_id,
            jtr.nkid,
            COUNT (DISTINCT clo.primary_key || clo.table_name) change_count,
            COUNT (DISTINCT c.attachment_id) document_count,
            CASE WHEN jtr.status = 2 THEN to_char (jtr.status_modified_date, 'mm/dd/yyyy HH24:MI:SS') END
               published_date,
            CASE WHEN jtr.next_rid IS NULL THEN 1 ELSE 0 END is_editable,
            jtr.status
       FROM VJURIS_TAX_REV_PK jtr
            JOIN juris_tax_chg_logs clo
               ON (clo.rid = jtr.rid) -- AND clo.entity_id = jtr.id)
            JOIN entity_table_map etm
               ON (    etm.table_name = clo.table_name
                   AND etm.logical_entity = 'Tax')
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