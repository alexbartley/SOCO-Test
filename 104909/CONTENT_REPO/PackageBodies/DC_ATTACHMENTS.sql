CREATE OR REPLACE PACKAGE BODY content_repo."DC_ATTACHMENTS" AS
/**
 * Doc template
 *
 *
 * A/ Ora Doc:: file/lob errors
 * -- ACCESS_ERROR 22925
 * -- LOB size is limited to 4 gigabytes.
 * etc..
 *
 * Insert attachment: dcSaveAttached
 * Sample functions
 *
 *
 */
  FUNCTION dcReturnID(sDocName IN varchar2) RETURN NUMBER IS
    nDocId NUMBER := NULL;
  BEGIN
    --try
    SELECT Max(id)
    INTO nDocId
    FROM
      attachments
    WHERE UPPER(display_name) LIKE UPPER('%'||sDocName||'%');
    RETURN nDocId;
  END;

  FUNCTION dcReturnFileSize(nDocId IN number) RETURN NUMBER IS
    nFileSize NUMBER := 0;
  BEGIN
    --try
    SELECT dbms_lob.getlength(LOB_LOC=>attached_file)
    INTO nFileSize
    FROM attachments
    WHERE id = nDocId;
    RETURN nFileSize;
  END;

  FUNCTION dcResContacts(nResSrcId IN number) RETURN VARCHAR2 IS
   sIdConcat varchar2(128);
   -- example: SELECT DC_ATTACHMENTS.dcResContacts(38) FROM dual
  BEGIN
    --SELECT wm_concat(P1=>rct.id)

    SELECT listagg(rct.id,',') WITHIN GROUP (ORDER BY rct.id)
    INTO sIdConcat
    FROM research_source_contacts rct
    JOIN research_sources rsc ON (rsc.id = rct.research_source_id)
    AND rsc.id = nResSrcId;
    RETURN sIdConcat;
  END;

  FUNCTION dcArchive(nDocId IN number) RETURN TIMESTAMP IS
    bDocFound BOOLEAN;
    nAttId NUMBER;
  BEGIN
    -- cpy
    NULL;
  END;

  /* PROC */
/*  PROCEDURE dcDocParam(sDescription IN VARCHAR2,
                       bArchived IN BOOLEAN,
                       dtExpiration IN DATE) IS
  BEGIN
    NULL;
  END;
*/

  /* dcReadAttachment */
  PROCEDURE dcReadAttachment(documentId IN NUMBER,
                             dcDoc OUT BLOB) IS
   sSQL varchar2(128) := 'Select docColumn <<blob>> From <<table>>
                          where id = :documentId';
  BEGIN
   --
   SELECT rdx.attached_file
   INTO dcDoc
   FROM attachments rdx
   WHERE rdx.id = documentId
   AND dbms_lob.getlength(LOB_LOC=>attached_file) > 0;
   --
  END;

  /* OL-SET */
/*  PROCEDURE dcSaveAttached(appFileName IN VARCHAR2,
                           sDescription IN VARCHAR2,
                           nAttachmentId IN NUMBER,
                           nResearchLogId IN NUMBER,
                           nEntered_By IN NUMBER) IS
  BEGIN
    NULL;
  END;

  PROCEDURE dcSaveAttached(appFileName IN VARCHAR2,
                           nAttachmentId IN NUMBER,
                           nResearchLogId IN NUMBER) IS
  BEGIN
    NULL;
  END;
*/
  PROCEDURE dcSaveAttached(appFileName IN VARCHAR2,
                           nAttachmentId IN NUMBER,
                           dcDoc IN OUT BLOB) IS
    vDocAttachment  BLOB; -- DEFAULT dcDoc;
    dc_internal_Doc BLOB;

    lMaxSize INTEGER := dbms_lob.lobmaxsize;
    ldestOffsetD INTEGER := 1;
    ldestOffsetS INTEGER := 1;
    lCSID NUMBER := dbms_lob.default_csid;
    lLang NUMBER := dbms_lob.default_lang_ctx;
    lWarning INTEGER := 0;
  BEGIN
    -- if using a CLOB conversion is needed
/*
    dbms_lob.createtemporary(dc_internal_Doc, true);
    dbms_output.put_line('Temp BLOB');
    dbms_lob.copy(DEST_LOB=>dc_internal_Doc, SRC_LOB=>dcDoc, AMOUNT=>lMaxSize, DEST_OFFSET=>ldestOffsetD,
    SRC_OFFSET=>ldestOffsetS);
    dbms_lob.converttoblob(DEST_LOB=>dc_internal_Doc
    , SRC_CLOB=>dcDoc
    , AMOUNT=>lMaxSize
    , DEST_OFFSET=>ldestOffsetD
    , SRC_OFFSET=>ldestOffsetS
    , BLOB_CSID=>lCSID
    , LANG_CONTEXT=>lLang
    , WARNING=>lWarning);
    dbms_output.put_line('Converted from CLOB to BLOB');
*/

    -- ToDo:: DB id should be the seqeuence or ID passed in
    -- here should be the Attachment table
    -- (not using the length since it is not known yet)

    -- Check before inserting either here or using another procedure
    -- before even get here to determine if an attachment can be added
    --> fnCheckStatus( id, ...) return status

    -- using dev table
    INSERT INTO rdx_documentation
    values(nAttachmentId, appFileName, dbms_lob.getlength(LOB_LOC=>dc_internal_Doc), EMPTY_BLOB())
    RETURNING doc_file INTO dcDoc;

    -- Return value 'dcDoc' to application
  END;


END;
/