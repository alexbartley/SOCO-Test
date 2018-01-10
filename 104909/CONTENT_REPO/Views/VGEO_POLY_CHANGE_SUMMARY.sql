CREATE OR REPLACE FORCE VIEW content_repo.vgeo_poly_change_summary ("ID",rid,nkid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents,veriftype) AS
(SELECT JCL.ID,
            JR.ID,
            JR.NKID,
            JCL.STATUS,
            (CASE WHEN JCL.STATUS = '2' THEN TO_CHAR (JR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                  ELSE RS.NAME
             END) published,
            TO_CHAR (JCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss') modified,
            U.FIRSTNAME || ' ' || U.LASTNAME entered_by,
            ETM.UI_ALIAS TABLE_NAME,
            CR.REASON,
            JCL.SUMMARY
            --, wm_concat(distinct A.ID) documents
            , LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID) documents
            -- either this or join to the assignment_type table
            --, listagg (getAssignmentTypeStr(vld.assignment_type_id),',') within group (order by a.id) VerifType
            -- regular concat using wm_concat(distinct getAssignmentTypeStr(vld.assignment_type_id)) VerifType
            --, wm_concat(distinct fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id)) VerifType
            , LISTAGG (fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id),',') WITHIN GROUP (ORDER BY a.id) VerifType
       FROM geo_poly_ref_revisions JR
            JOIN geo_poly_ref_chg_logs JCL
               ON JR.ID = JCL.RID
            left join geo_poly_ref_chg_vlds vld on (vld.geo_poly_ref_chg_log_id = jcl.id)
            JOIN ENTITY_TABLE_MAP ETM
               ON JCL.TABLE_NAME = ETM.TABLE_NAME
            LEFT OUTER JOIN CHANGE_REASONS CR
               ON JCL.REASON_ID = CR.ID
            LEFT OUTER JOIN geo_poly_ref_chg_cits JCC
               ON JCL.ID = JCC.geo_poly_ref_chg_log_id
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
            TO_CHAR (JCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            ETM.UI_ALIAS,
            CR.REASON,
            JCL.SUMMARY
            );