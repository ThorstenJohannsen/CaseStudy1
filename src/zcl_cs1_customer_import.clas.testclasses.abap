CLASS ltc_cust_import DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO lcl_customer_import.

    METHODS:
      setup,
      test_email_valid         FOR TESTING,
      test_phone_valid         FOR TESTING,
      test_fax_valid           FOR TESTING,
      test_get_next_id         FOR TESTING.
ENDCLASS.


CLASS ltc_cust_import IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW lcl_customer_import( ).
  ENDMETHOD.


  METHOD test_email_valid.
    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = mo_cut->is_email_valid( 'test@beispiel.de' )
      msg = 'Valid email should return true' ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = mo_cut->is_email_valid( 'invalid@' )
      msg = 'Invalid email should return false' ).
  ENDMETHOD.


  METHOD test_phone_valid.
    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = mo_cut->is_tel_valid( '+49 176 12345678' ) ).
  ENDMETHOD.


  METHOD test_fax_valid.
    cl_abap_unit_assert=>assert_equals(
      exp = mo_cut->is_tel_valid( '089 123456' )
      act = mo_cut->is_fax_valid( '089 123456' ) ).
  ENDMETHOD.


  METHOD test_get_next_id.
    TRY.
        DATA(lv_id) = mo_cut->get_next_customer_id( ).
        cl_abap_unit_assert=>assert_not_initial( lv_id ).
      CATCH cx_number_ranges.
        cl_abap_unit_assert=>fail( 'Nummernkreis Fehler' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
