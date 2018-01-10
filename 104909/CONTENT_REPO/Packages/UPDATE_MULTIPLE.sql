CREATE OR REPLACE PACKAGE content_repo."UPDATE_MULTIPLE"
IS
  E_Mandatory EXCEPTION;

  Function umLogStat(ProcessId in number) return number;
  Function umLogReturn(ProcessId in number) return varchar2;
  FUNCTION XMLForm_TaxesDefinition(form_xml_i IN SYS.XMLType) RETURN XMLForm_TaxDefn_TT PIPELINED;

  PROCEDURE remove_tax_description (
            id_i IN NUMBER,
            deleted_by_i IN NUMBER,
            jurisdiction_id_i IN number,
            pDelete OUT number
  );
  PROCEDURE remove_attribute (
            id_i IN NUMBER,
            deleted_by_i IN NUMBER,
            pDelete OUT number
  );
  PROCEDURE remove_tax_attribute (
            id_i IN NUMBER,
            deleted_by_i IN NUMBER,
            pDelete OUT number
  );

  /*
   sx as XML Clob
   success Status 0/1
   process_id returned log id
  */
  PROCEDURE process_xml(sx IN CLOB, success OUT NUMBER, process_id OUT NUMBER);
  PROCEDURE Tax_Definition(insx IN CLOB, success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER);

END update_multiple;
 
/