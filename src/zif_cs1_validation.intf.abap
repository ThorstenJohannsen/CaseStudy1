INTERFACE zif_cs1_validation
  PUBLIC .


  METHODS is_email_valid
    IMPORTING iv_email        TYPE zcs1_customers-email
    RETURNING VALUE(rv_valid) TYPE abap_bool.

  METHODS is_phone_valid
    IMPORTING iv_phone        TYPE zcs1_customers-phone
    RETURNING VALUE(rv_valid) TYPE abap_bool.

  METHODS is_fax_valid
    IMPORTING iv_fax          TYPE zcs1_customers-fax
    RETURNING VALUE(rv_valid) TYPE abap_bool.

  METHODS latenumbering
    RETURNING VALUE(rv_id) TYPE zcustomerid1.

  INTERFACES if_oo_adt_classrun .
ENDINTERFACE.
