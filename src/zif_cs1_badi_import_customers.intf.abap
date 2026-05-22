INTERFACE zif_cs1_badi_import_customers
  PUBLIC .


  INTERFACES if_badi_interface .
  INTERFACES if_oo_adt_classrun .
  METHODS after_import
    IMPORTING
      it_new TYPE string_table " Liste der neuen Kunden/Firman aus dem Importprogramm
      it_error          TYPE string_table " Liste der IDs/Fehlermeldungen
      it_raw          TYPE string_table. " Liste der CSV Daten


ENDINTERFACE.
