CREATE OR REPLACE FUNCTION content_repo.pft_return_1(
  record_rid_i IN NUMBER, 
  entity_rid_i IN NUMBER, 
  record_next_rid_i IN NUMBER
  ) RETURN  NUMBER IS
  l_reval NUMBER := 0;
BEGIN
    --if the record's revision is with the range of a given Entity RID and NEXT_RID
    IF (
        entity_rid_i >= record_rid_i
        AND entity_rid_i < nvl(record_next_rid_i, 999999999999)
        ) THEN
        l_reval := 1;
    END IF;
    RETURN(l_reval);
END pft_return_1;
 
/