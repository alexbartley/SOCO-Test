CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_change_summary ("ID",rid,nkid,jurisdiction_nkid,jurisdiction_rid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents,veriftype) AS
SELECT JTCL.ID,
            JTR.ID,
            JTR.NKID,
            J.NKID JURISDICTION_NKID,
            J.RID JURISDICTION_RID,
            JTCL.STATUS,
            (CASE
                WHEN JTCL.STATUS = '2'
                THEN
                   TO_CHAR (JTR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                ELSE
                   RS.NAME
             END),
            TO_CHAR (JTCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            etm.ui_alias||': '||q.qr TABLE_NAME,
            CR.REASON,
            JTCL.SUMMARY
            --, wm_concat(distinct A.ID) documents
            , LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID) documents
            -- either this or join to the assignment_type table
            --, listagg (getAssignmentTypeStr(vld.assignment_type_id),',') within group (order by a.id) VerifType
            -- regular concat using wm_concat(distinct getAssignmentTypeStr(vld.assignment_type_id)) VerifType
            --, wm_concat(distinct fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id)) VerifType
            , listagg (fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id),',') within group (order by a.id) VerifType
      FROM JURISDICTION_TAX_REVISIONS JTR
            JOIN JURIS_TAX_CHG_LOGS JTCL
               ON JTR.ID = JTCL.RID
            join tax_qr q on (q.table_name = jtcl.table_name and q.ref_id = jtcl.primary_key)
            left join juris_tax_chg_vlds vld on (vld.juris_tax_chg_log_id=jtcl.id)
            JOIN JURIS_TAX_IMPOSITIONS JTI
               ON JTI.ID = JTCL.ENTITY_ID
            JOIN JURISDICTIONS J
               ON J.ID = JTI.JURISDICTION_ID
            JOIN ENTITY_TABLE_MAP ETM
               ON JTCL.TABLE_NAME = ETM.TABLE_NAME
            LEFT OUTER JOIN CHANGE_REASONS CR
               ON JTCL.REASON_ID = CR.ID
            LEFT OUTER JOIN JURIS_TAX_CHG_CITS JTCC
               ON JTCL.ID = JTCC.JURIS_TAX_CHG_LOG_ID
            LEFT OUTER JOIN CITATIONS C
               ON JTCC.CITATION_ID = C.ID
            LEFT OUTER JOIN ATTACHMENTS A
               ON C.ATTACHMENT_ID = A.ID
            JOIN RECORD_STATUSES RS
               ON JTCL.STATUS = RS.ID
            JOIN USERS U
               ON JTCL.ENTERED_BY = U.ID
   GROUP BY JTCL.ID,
            JTR.ID,
            JTR.NKID,
            J.NKID,
            J.RID,
            JTCL.STATUS,
            (CASE
                WHEN JTCL.STATUS = '2'
                THEN
                   TO_CHAR (JTR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                ELSE
                   RS.NAME
             END),
            TO_CHAR (JTCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            etm.ui_alias||': '||q.qr,
            CR.REASON,
            JTCL.SUMMARY;