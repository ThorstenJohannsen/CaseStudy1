CLASS zcl_cs1_badi_impl DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .


  PUBLIC SECTION.
    DATA it_tab1 TYPE string_table.
    DATA it_tab2 TYPE string_table.
    DATA it_tab3 TYPE string_table.

    INTERFACES if_oo_adt_classrun .
    INTERFACES if_badi_interface .
    INTERFACES zif_cs1_badi_import_customers .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CS1_BADI_IMPL IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
*    out->write( |Tabelle für neue Kunden:| ).
*    out->write(  it_tab1 ).
*    out->write( |Tabelle der gefundenen Fehler:| ).
*    out->write(  it_tab2 ).
*    out->write( |Tabelle der Rohdaten:| ).
*    out->write(  it_tab3 ).

  ENDMETHOD.


  METHOD zif_cs1_badi_import_customers~after_import.

    it_tab1 = it_new.
    it_tab2 = it_error.
    it_tab3 = it_raw.


  ENDMETHOD.
ENDCLASS.
