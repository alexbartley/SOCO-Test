CREATE OR REPLACE FUNCTION content_repo."REV_JOIN2" (
  record_rid_i IN NUMBER, --the RID from the source table of the data, e.g. Jurisdictions.RID, Tax_Definitions.RID
  entity_rid_i IN NUMBER, --the ID from the REVISION table [Entity]_Revisions.ID
  record_next_rid_i IN NUMBER --the NEXT_RID from the source table e.g. Jurisdictions.NEXT_RID, Tax_Definitions.NEXT_RID
  )
  RETURN  NUMBER IS
  l_reval NUMBER := 0;
BEGIN
    --if the record's revision is with the range of a given Entity RID and NEXT_RID
    IF (
        entity_rid_i <= record_rid_i
        AND entity_rid_i < nvl(record_next_rid_i, 999999999999)
        ) THEN
        l_reval := 1;
    ELSIF (
        record_rid_i IS NULL
        ) THEN
        l_reval := 1;
    END IF;
    RETURN l_reval;
END;

 
 
/