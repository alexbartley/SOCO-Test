CREATE OR REPLACE FORCE VIEW content_repo.vkpmg_zip4_final (area_id,zip,plus4_range,default_flag,state_code) AS
(SELECT /*+ parallel(j1,8) parallel(j2,8)*/  DISTINCT j2.AREA_ID,j2.ZIP,j2.PLUS4_RANGE,j2.DEFAULT_FLAG,j2.STATE_CODE
                  FROM kpmg_zip_extract_pt3 j1
                       JOIN kpmg_zip_extract_pt j2
                           ON (    j1.area_id = j2.area_id
                               AND j1.zip = j2.zip
                               AND j1.state_code = j2.state_code
                               AND j2.plus4_range IS NOT NULL
                               AND j2.default_flag = 'Y')
                 WHERE j1.state_code = j2.state_code
);