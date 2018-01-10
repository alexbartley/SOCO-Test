CREATE OR REPLACE FUNCTION content_repo."CTX_RET_PROGRESSION" (sSearchCriteria IN VARCHAR2,
nInclude_wild IN NUMBER DEFAULT 0,
nFuzzyLogic IN NUMBER DEFAULT 0)
RETURN CLOB IS
--
-- Search token transform [alpha]
-- tnn

  l_SearchCriteria varchar2(128);
  nIncludeW BOOLEAN := (nInclude_wild=1);
  nFuzzy BOOLEAN := (nFuzzyLogic=1);
  sxQuery CLOB :='<query>
  <textquery lang="ENGLISH" grammar="CONTEXT">{s}
  <progression>
  <seq><rewrite>transform((TOKENS, "{", "}", "AND"))</rewrite></seq>
  <seq><rewrite>transform((TOKENS, "?{", "}", "AND"))</rewrite>/seq>
  <seq><rewrite>transform((TOKENS, "${", "}", "AND"))</rewrite></seq>
  <seq><rewrite>transform((TOKENS, "!", "%", "AND"))</rewrite></seq>
  <seq><rewrite>transform((TOKENS, "{", "}", "OR"))</rewrite></seq>
  <seq><rewrite>transform((TOKENS, "?{", "}", "OR"))</rewrite>/seq>
  <seq><rewrite>transform((TOKENS, "${", "}", "OR"))</rewrite></seq>
  <seq><rewrite>transform((TOKENS, "!", "%", "OR"))</rewrite></seq>
  </progression>
  </textquery>
  <score datatype="INTEGER" algorithm="DEFAULT"/>
  </query>';
BEGIN
  l_SearchCriteria:=REGEXP_REPLACE(REGEXP_REPLACE(sSearchCriteria,
                   '([^[:alpha:]])',' ')
                   ,'(\ {1,})( *?)\1+',
                   '\1');

  sxQuery:=REGEXP_REPLACE(sxQuery,'{s}',l_SearchCriteria);
  RETURN sxQuery;
END;
 
/