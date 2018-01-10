CREATE OR REPLACE FORCE VIEW content_repo.vjuris_change_summary ("ID",rid,nkid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents,veriftype) AS
SELECT JCL.ID,
            JR.ID,
            JR.NKID,
            JCL.STATUS,
            (CASE
                WHEN JCL.STATUS = '2'
                THEN
                   TO_CHAR (JR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                ELSE
                   RS.NAME
             END),
            TO_CHAR (JCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            --ETM.UI_ALIAS TABLE_NAME,
            ETM.UI_ALIAS||': '||q.qr,
            CR.REASON,
            JCL.SUMMARY,
            --wm_concat(distinct A.ID)
            LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID)
            -- either this or join to the assignment_type table
            --, listagg (getAssignmentTypeStr(vld.assignment_type_id),',') within group (order by a.id) VerifType
            -- regular concat using wm_concat(distinct getAssignmentTypeStr(vld.assignment_type_id)) VerifType
            --,wm_concat(distinct fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id)) VerifType
            , listagg (fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id),',') within group (order by a.id) VerifType            
       FROM JURISDICTION_REVISIONS JR
            JOIN JURIS_CHG_LOGS JCL
               ON JR.ID = JCL.RID
            JOIN juris_qr q on (q.table_name = JCL.table_name and q.ref_id = JCL.primary_key)
            LEFT JOIN juris_chg_vlds vld on (vld.juris_chg_log_id = jcl.id)
            JOIN ENTITY_TABLE_MAP ETM
               ON JCL.TABLE_NAME = ETM.TABLE_NAME
            LEFT OUTER JOIN CHANGE_REASONS CR
               ON JCL.REASON_ID = CR.ID
            LEFT OUTER JOIN JURIS_CHG_CITS JCC
               ON JCL.ID = JCC.JURIS_CHG_LOG_ID
            LEFT OUTER JOIN CITATIONS C
               ON JCC.CITATION_ID = C.ID
            LEFT OUTER JOIN ATTACHMENTS A
               ON C.ATTACHMENT_ID = A.ID
            JOIN RECORD_STATUSES RS
               ON JCL.STATUS = RS.ID
            JOIN USERS U
               ON JCL.ENTERED_BY = U.ID
   GROUP BY JCL.ID,
            JR.ID,
            JR.NKID,
            JCL.STATUS,
            (CASE
                WHEN JCL.STATUS = '2'
                THEN
                   TO_CHAR (JR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                ELSE
                   RS.NAME
             END),
            ETM.UI_ALIAS||': '||q.qr,
            TO_CHAR (JCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            CR.REASON,
            JCL.SUMMARY;