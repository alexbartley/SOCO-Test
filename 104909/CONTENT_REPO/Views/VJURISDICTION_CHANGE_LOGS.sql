CREATE OR REPLACE FORCE VIEW content_repo.vjurisdiction_change_logs ("ID",juris_nkid,juris_rid,primary_key,status,status_id,status_modified_date,entered_date,entered_by,entered_by_id,table_name,change_reason,change_reason_id,assignment_type,assignment_type_id,jurisdiction,change_summary,document_count) AS
SELECT jcl.id,
            jr.nkid,
            jr.id,
            jcl.primary_key,
            rs.name,
            jr.status,
            jcl.status_modified_date,
            jcl.entered_date,
            u.username,
            jcl.entered_by,
            etm.ui_alias table_name,
            cr.reason,
            jcl.reason_id,
            LISTAGG(at.name, ', '||'') WITHIN GROUP (ORDER BY at.NAME) over (PARTITION BY jcl.id),
            jcv.assignment_type_id,
            j.official_name,
            jcl.summary,
            COUNT (DISTINCT ci.attachment_id)
       FROM juris_chg_logs jcl
            JOIN entity_table_map etm
               ON (etm.table_name = jcl.table_name)
            JOIN jurisdiction_revisions jr
               ON (jr.id = jcl.rid)
            JOIN jurisdictions j
               ON (j.id = jcl.entity_id)
            LEFT OUTER JOIN juris_chg_cits jcc
               ON (jcc.juris_chg_log_id = jcl.id)
            LEFT OUTER JOIN citations ci
               ON (jcc.citation_id = ci.id)
            LEFT OUTER JOIN change_reasons cr
               ON (cr.id = jcl.reason_id)
            LEFT OUTER JOIN juris_chg_vlds jcv
               ON (jcv.juris_chg_log_id = jcl.id)
            LEFT OUTER JOIN assignment_types at
               ON (at.id = jcv.assignment_type_id)
            JOIN users u
               ON (u.id = jcl.entered_by)
            JOIN record_statuses rs
               ON (rs.id = jr.status)
      WHERE logical_entity = 'Jurisdiction'
   GROUP BY jcl.id,
            jr.nkid,
            jr.id,
            jcl.primary_key,
            rs.name,
            jr.status,
            jcl.status_modified_date,
            jcl.entered_date,
            etm.ui_alias,
            u.username,
            jcl.entered_by,
            cr.reason,
            jcl.reason_id,
            at.name,
            jcv.assignment_type_id,
            j.official_name,
            jcl.summary
 
 
 ;