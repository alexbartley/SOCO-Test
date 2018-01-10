CREATE OR REPLACE FORCE VIEW content_repo.vcomm_change_summary ("ID",rid,nkid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents,veriftype) AS
SELECT ACL.ID,
            AR.ID,
            AR.NKID,
            ACL.STATUS,
            (CASE WHEN ACL.STATUS = '2' THEN TO_CHAR (AR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                  ELSE RS.NAME
             END) published,
            TO_CHAR (ACL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss') modified,
            U.FIRSTNAME || ' ' || U.LASTNAME entered_by,
            ETM.UI_ALIAS || ': ' || q.qr TABLE_NAME,
            CR.REASON,
            ACL.SUMMARY
            , LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID) documents
            --, listagg (getAssignmentTypeStr(vld.assignment_type_id),',') within group (order by a.id) VerifType
            --, wm_concat(distinct getAssignmentTypeStr(vld.assignment_type_id)) VerifType
            --, wm_concat (DISTINCT A.ID) documents
            --, wm_concat (DISTINCT fnAssignmentAbbr (vld.assignment_type_id)||' '||get_username (vld.assigned_user_id)) VerifType
            , LISTAGG (fnAssignmentAbbr(vld.assignment_type_id)||' '||get_username (vld.assigned_user_id),',') WITHIN GROUP (ORDER BY a.id) VerifType
       FROM commodity_REVISIONS AR
            JOIN comm_CHG_LOGS ACL
               ON AR.ID = ACL.RID
            JOIN comm_qr q
               ON (q.table_name = ACL.table_name AND q.ref_id = ACL.primary_key)
            LEFT JOIN comm_chg_vlds vld
               ON (vld.comm_chg_log_id = acl.id)
            JOIN ENTITY_TABLE_MAP ETM
               ON ACL.TABLE_NAME = ETM.TABLE_NAME
            LEFT OUTER JOIN CHANGE_REASONS CR
               ON ACL.REASON_ID = CR.ID
            LEFT OUTER JOIN comm_CHG_CITS ACC
               ON ACL.ID = ACC.comm_CHG_LOG_ID
            LEFT OUTER JOIN CITATIONS C
               ON ACC.CITATION_ID = C.ID
            LEFT OUTER JOIN ATTACHMENTS A
               ON C.ATTACHMENT_ID = A.ID
            JOIN RECORD_STATUSES RS
               ON ACL.STATUS = RS.ID
            JOIN USERS U
               ON ACL.ENTERED_BY = U.ID
   GROUP BY ACL.ID,
            AR.ID,
            AR.NKID,
            ACL.STATUS,
            (CASE WHEN ACL.STATUS = '2' THEN TO_CHAR (AR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                  ELSE RS.NAME
             END),
            TO_CHAR (ACL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            ETM.UI_ALIAS || ': ' || q.qr,
            CR.REASON,
            ACL.SUMMARY;