CREATE OR REPLACE PACKAGE BODY content_repo."CTX_CONTENT_REPO_LIB" as
--
 PROCEDURE dev_ctx_jti_ccset(p_rowid IN ROWID
                            ,p_clob  IN OUT CLOB)
 IS
 -- dataset for Juris Tax Imposition
 v_clob            CLOB;
BEGIN
 FOR c1 IN
   (SELECT jti.id
         , jti.jurisdiction_id
         , jti.entered_by
         , jti.reference_code ||' '||jti.description AS data
    FROM   juris_tax_impositions jti
    WHERE  ROWID = p_rowid)
 LOOP
   v_clob := v_clob || c1.data;

   For txdfn in
     (Select ' '|| txd.value_type ||' '||txd.value as data
      -- txo.start_date txo.end_date
      from tax_outlines txo
      join tax_definitions txd on (txd.tax_outline_id = txo.id)
      where txo.juris_tax_imposition_id = c1.id)
   LOOP
     v_clob := v_clob||txdfn.data;
   end loop;

   -- User Info (either here or as lookup after dataset is created in UI)
   FOR c2 IN
      (SELECT ' '||username||' '||firstname||' '||lastname AS data
       FROM   users a
       WHERE  a.id = c1.entered_by)
   LOOP
       v_clob := v_clob || c2.data;
   END LOOP;

   -- Jurisdiction info
   FOR c3 IN
      (SELECT ' '||a.official_name||' '||a.description AS data
       FROM   jurisdictions a
       WHERE  a.id = c1.jurisdiction_id)
   LOOP
       v_clob := v_clob || c3.data;
   END LOOP;
  END LOOP;
  p_clob := v_clob;
END dev_ctx_jti_ccset;

end ctx_content_repo_lib;
/