CREATE OR REPLACE PACKAGE content_repo."CTX_CONTENT_REPO_LIB" as
 -- CTX Base Lib
 -- Datasets
 -- V 0.1

 -- 7/13: Base
 -- Add dbms_lob.append(dest_lob=> ?, src_lob=> ?)
 -- Use MT view with smaller columns UNION
 -- Cpy LC
 -- Proc for Applicability
 -- Attributes and lookup tables
 -- Commodities ()


 PROCEDURE dev_ctx_jti_ccset(p_rowid IN ROWID
                            ,p_clob  IN OUT CLOB);

end ctx_content_repo_lib;




 
/