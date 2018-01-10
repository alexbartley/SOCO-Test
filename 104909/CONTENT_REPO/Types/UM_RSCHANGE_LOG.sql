CREATE OR REPLACE TYPE content_repo."UM_RSCHANGE_LOG"                                          AS OBJECT
   (
          id number,            -- change log id
          rid number,
          entity_id number,
          primary_key number
   );
/