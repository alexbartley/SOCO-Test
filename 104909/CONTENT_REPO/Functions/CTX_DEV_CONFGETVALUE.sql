CREATE OR REPLACE FUNCTION content_repo."CTX_DEV_CONFGETVALUE"
  (p_param VARCHAR2,
   p_app_id  NUMBER,
   p_role_id NUMBER
  )
  RETURN VARCHAR2
  RESULT_CACHE RELIES_ON
    (CTX_DEV_role_lvl_config_params,
     CTX_DEV_app_lvl_config_params,
     CTX_DEV_global_config_params
    )
IS
  answer VARCHAR2(20);
BEGIN
  -- Is parameter set at role level?
  BEGIN
    SELECT value INTO answer
      FROM CTX_DEV_role_lvl_config_params
        WHERE role_id = p_role_id
          AND name = p_param;
    RETURN answer;  -- Found
    EXCEPTION
      WHEN no_data_found THEN
        NULL;  -- Fall through to following code
  END;
  -- Is parameter set at application level?
  BEGIN
    SELECT value INTO answer
      FROM CTX_DEV_app_lvl_config_params
        WHERE app_id = p_app_id
          AND name = p_param;
    RETURN answer;  -- Found
    EXCEPTION
      WHEN no_data_found THEN
        NULL;  -- Fall through to following code
  END;
  -- Is parameter set at global level?
    SELECT value INTO answer
     FROM CTX_DEV_global_config_params
      WHERE name = p_param;
    RETURN answer;
END;

 
 
/