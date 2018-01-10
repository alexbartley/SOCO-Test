CREATE OR REPLACE FORCE VIEW content_repo.vkpmg_zip5_final (area_id,zip,default_flag,state_code) AS
SELECT /*+ parallel(j1,8) parallel(j2,8)*/ DISTINCT j1.AREA_ID,j1.ZIP,j1.DEFAULT_FLAG,j1.STATE_CODE
                  FROM kpmg_zip_extract_pt3 j1
                       JOIN kpmg_zip_extract_pt j2
                           ON (    j1.area_id = j2.area_id
                               AND j1.zip = j2.zip
                               AND j1.state_code = j2.state_code
                               AND j2.default_flag = 'Y')
                 WHERE j1.state_code = j2.state_code;