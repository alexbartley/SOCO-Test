CREATE OR REPLACE FUNCTION content_repo.dev_use_exec_bind(p_loc VARCHAR2, p_job NUMBER) 
RETURN NUMBER
IS
  -- p_loc = tablename
  -- p_job (id etc. in this case; 'rid')
  v_query_str VARCHAR2(1000);
  v_num_of_recs NUMBER;
BEGIN
  v_query_str := 'SELECT COUNT(*) FROM ' 
                 || p_loc
                 || ' WHERE rid = :bind_job';                           
  EXECUTE IMMEDIATE v_query_str
    INTO v_num_of_recs
    USING p_job;
  RETURN v_num_of_recs;
END;
 
 
 
 
/