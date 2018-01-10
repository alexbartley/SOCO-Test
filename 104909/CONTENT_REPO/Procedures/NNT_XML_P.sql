CREATE OR REPLACE PROCEDURE content_repo."NNT_XML_P" (puiusr IN NUMBER, pPart IN NUMBER, inxml IN clob) IS
  PRAGMA autonomous_transaction;
BEGIN
  -- simple insert for now
  EXECUTE IMMEDIATE 'INSERT INTO nnt_tx_xml_i values(SYSDATE, :puiusr, :pPart, :inxml)'
  USING puiusr, pPart, inxml;
  COMMIT;
END;
 
 
 
/