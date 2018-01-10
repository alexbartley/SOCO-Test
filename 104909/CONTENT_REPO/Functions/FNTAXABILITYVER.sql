CREATE OR REPLACE FUNCTION content_repo."FNTAXABILITYVER" (pRID IN NUMBER) RETURN VARCHAR2
IS
    -- ************************************************************* --
    -- CRAPP-2563 - Created to return Taxability Verification Levels --
    -- ************************************************************* --

    l_verification VARCHAR2(10);
BEGIN
    WITH summary AS
        (
         SELECT rid
                , nkid
                , status
                , veriftype
                , chgcnt
                , MIN(status) minstatus
                , SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) Pendcnt
                , SUM(CASE WHEN INSTR(veriftype, 'R1') <> 0 THEN 1 ELSE 0 END) R1cnt
                , SUM(CASE WHEN INSTR(veriftype, 'R2') <> 0 THEN 1 ELSE 0 END) R2cnt
                , SUM(CASE WHEN INSTR(veriftype, 'FR') <> 0 THEN 1 ELSE 0 END) FRcnt
                , SUM(CASE WHEN INSTR(veriftype, 'TS') <> 0 THEN 1 ELSE 0 END) TScnt
         FROM (
               SELECT JTCL.ID
                      , JTR.ID  RID
                      , JTR.NKID
                      , JTCL.STATUS
                      , chgcnt
                      , LISTAGG (fnAssignmentAbbr(vld.assignment_type_id), ',') WITHIN GROUP (ORDER BY jtcl.id) VerifType
               FROM juris_tax_app_revisions JTR
                    JOIN juris_tax_app_chg_logs JTCL ON jtr.id = jtcl.rid
                    JOIN (
                          SELECT rid, COUNT(rid) chgcnt
                          FROM juris_tax_app_chg_logs
                          GROUP BY rid
                         ) c ON jtr.id = c.rid
                    LEFT JOIN juris_tax_app_chg_vlds vld ON (vld.juris_tax_app_chg_log_id = jtcl.id)
               WHERE jtr.id = pRid
               GROUP BY
                    JTCL.ID
                    , JTR.ID
                    , JTR.NKID
                    , JTCL.STATUS
                    , JTCL.SUMMARY
                    , chgcnt
              )
         GROUP BY
               rid
               , nkid
               , status
               , veriftype
               , chgcnt
        )
        , verresults AS (
          SELECT vc.rid
                 , minstatus
                 , status
                 , Chgcnt
                 , FRcnt
                 , R2cnt
                 , R1cnt
                 , TScnt
                 , CASE WHEN minstatus = 0 AND Pendcnt > 0 THEN 'Pending'
                        ELSE CASE WHEN minstatus > 0 AND status = 1 AND FRcnt = Chgcnt THEN 'FR'
                                  WHEN minstatus > 0 AND status = 1 AND FRcnt < Chgcnt AND R2cnt = Chgcnt THEN 'R2'
                                  WHEN minstatus > 0 AND status = 1 AND FRcnt < Chgcnt AND R2cnt < Chgcnt AND R1cnt = Chgcnt THEN 'R1'
                        WHEN minstatus > 0 AND status = 1 AND FRcnt < Chgcnt AND R2cnt < Chgcnt AND R1cnt < Chgcnt AND TScnt < Chgcnt THEN 'Pending'
                        WHEN minstatus > 0 AND status = 1 AND FRcnt < Chgcnt AND R2cnt < Chgcnt AND R1cnt < Chgcnt AND TScnt = Chgcnt THEN 'TS'
                        WHEN minstatus > 0 AND status = 2 THEN 'FR'
                             END
                   END verification
          FROM summary vc
        )
        , verorder AS (
         SELECT rid
                , verification
                , CASE WHEN verification = 'Pending' THEN 0 ELSE ui_order END ui_order
         FROM   verresults v
                LEFT JOIN assignment_types a ON (DECODE(v.verification,'FR','Final Review','R1','Review 1','R2','Review 2',NULL) = a.NAME)
        )
        , verranking AS (
         SELECT rid
                , verification
                , RANK() OVER( PARTITION BY rid ORDER BY ui_order) verrank
         FROM verorder
        )
        SELECT DISTINCT verification
        INTO l_verification
        FROM verranking
        WHERE verrank = 1;

  RETURN l_verification;
END;
/