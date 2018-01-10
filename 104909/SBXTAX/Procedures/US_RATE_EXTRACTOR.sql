CREATE OR REPLACE PROCEDURE sbxtax."US_RATE_EXTRACTOR"
   ( extract_date IN varchar2)
   IS

CURSOR states IS
SELECT code, name
FROM tb_states
WHERE us_state = 'Y'
OR code IN ('PR','GU','VI')
ORDER BY code;

BEGIN
    FOR state IN states LOOP
        rate_extract(state.code||'_RATE_EXTRACT_'||extract_date||'.TXT', extract_date, state.name);
    END LOOP;

END;



 
 
/