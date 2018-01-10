CREATE OR REPLACE PACKAGE content_repo."DC_ATTACHMENTS" AS
/** Documentation Upload, Read
 *
 *


-- DEV table
 CREATE TABLE rdx_documentation
(
 doc_key NUMBER NOT null,
 doc_name varchar2(128),
 file_size NUMBER,
 doc_file BLOB
)

 */
  -- dev temp
  DX_TABLE       CONSTANT VARCHAR2(32) := 'CONTENT_DOCUMENTS';

  FUNCTION dcReturnID(sDocName IN varchar2) RETURN NUMBER;     -- id of doc
  FUNCTION dcReturnFileSize(nDocId IN number) RETURN NUMBER;   -- filesize
  FUNCTION dcResContacts(nResSrcId IN number) RETURN VARCHAR2;
  FUNCTION dcArchive(nDocId IN number) RETURN TIMESTAMP;       -- archive doc

  --PROCEDURE dcDocParam(sDescription IN VARCHAR2,
  --                     bArchived IN BOOLEAN,
  --                     dtExpiration IN DATE);

  /* OL-SET */
/*  PROCEDURE dcSaveAttached(appFileName IN VARCHAR2,
                           sDescription IN VARCHAR2,
                           nAttachmentId IN NUMBER,
                           nResearchLogId IN NUMBER,
                           nEntered_By IN NUMBER,
                           dcDoc IN BLOB);

  PROCEDURE dcSaveAttached(appFileName IN VARCHAR2,
                           nAttachmentId IN NUMBER,
                           nResearchLogId IN NUMBER,
                           dcDoc IN BLOB);
*/
  PROCEDURE dcSaveAttached(appFileName IN VARCHAR2,
                           nAttachmentId IN NUMBER,
                           dcDoc IN OUT BLOB);


  /* OL dcReadAttachment
  PROCEDURE dcReadAttachment(documentName IN VARCHAR2,
                             dcDoc OUT BLOB);

  PROCEDURE dcReadAttachment(citationId IN NUMBER,
                             dcDoc OUT BLOB);
  */

  PROCEDURE dcReadAttachment(documentId IN NUMBER,
                             dcDoc OUT BLOB);

END;
/