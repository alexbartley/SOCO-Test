CREATE OR REPLACE PACKAGE content_repo."TAXABILITY_COPY" AS
/*
|| Copy taxability records to Jurisdictions
||
*/
  -- selected copy material
  PROCEDURE copyItems(pTaxabilityId in clob, oProcessId out number, pEnteredBy in number);

  -- process list of jurisdiction based on UI selection and process id
  -- What process id (taxability items) and what selected Jurisdiction
  PROCEDURE processCopy(pProcessId in number, selectedJuris in clob, errMsg in out varchar2);
     -- OVL
	 -- Changes for CRAPP-2721
     PROCEDURE processCopy(pProcessId in number, defStartDate in date, selectedJuris in clob, errMsg in out varchar2, defEndDate in date default null);

  -- return valid jurisdictions to copy to
  PROCEDURE getJurisdictions(pProcessId in number, ojuris_list in out clob);


  /*
  || Copy taxability based on Commodity
  || UI: Commodity Grid
  */
  FUNCTION  getcopyjtacomm(pProcessId in number) Return copy_comm_jta_t;
  PROCEDURE copyCommodity(pTaxabilityId in clob, oProcessId out number, pEnteredBy in number);
  PROCEDURE getCommodities(pProcessId in number);
  -- Changes for CRAPP-2721
  PROCEDURE processCopyComm(pProcessId in number, defStartDate in date, selectedComm in clob, errMsg in out varchar2, defEndDate in date default null);

END Taxability_Copy;
/