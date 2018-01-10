CREATE OR REPLACE FUNCTION content_repo."PHP_IS_SOMETHING" (p in number) return boolean as
    -- OCI OCI 8.2.0.7 - Oracle 12c support for boolean
    begin
      if (p < 10) then
        return true;
      else
        return false;
      end if;

    /* How To in PHP example
       ---------------------
      $c = oci_connect('schm', 'pwd', '@db');
      $sql = "begin :r := is_valid(40); end;";
      $s = oci_parse($c, $sql);
      oci_bind_by_name($s, ':r', $r, -1, SQLT_BOL);  // no need to give length
      oci_execute($s);
      var_dump($r);                                  // Output: bool(false)
    */
    end;

 
 
/