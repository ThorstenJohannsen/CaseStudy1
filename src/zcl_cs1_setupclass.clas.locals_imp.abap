*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_setup_handler DEFINITION.
  PUBLIC SECTION.
    " Implementiert das Setup-Interface für run_setup( )
    INTERFACES zif_system_setup1.

  PRIVATE SECTION.
    " -----------------------------------------------------------------
    " Konstanten für Nummernkreis-Objekte
    " c_obj_cust: Nummernkreis für Customer-ID -> ZCS_CUST1
    " c_obj_err:  Nummernkreis für Error-ID -> ZCS_IDERR1
    " c_range_01: Intervall '01' wird in beiden Objekten genutzt
    " -----------------------------------------------------------------
    CONSTANTS: c_obj_cust TYPE cl_numberrange_intervals=>nr_object VALUE 'ZCS_CUST1',
               c_obj_err  TYPE cl_numberrange_intervals=>nr_object VALUE 'ZCS_IDERR1',
               c_range_01 TYPE cl_numberrange_runtime=>nr_interval   VALUE '01'.

    " Erstellt Nummernkreis-Intervalle für beide Objekte
    METHODS setup_number_range
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out OPTIONAL.

    " Hilfsmethode: Legt Intervall 000001-999999 für ein Objekt an
    " Vermeidet doppelten Code für ZCS_CUST1 und ZCS_IDERR1
    METHODS create_interval
      IMPORTING iv_object TYPE cl_numberrange_intervals=>nr_object
                out       TYPE REF TO if_oo_adt_classrun_out OPTIONAL.

    " Setzt Nummernkreis-Level auf 0 zurück wenn Tabelle leer ist
    " Verhindert Lücken nach DELETE FROM
    METHODS setup_service_table
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out OPTIONAL.
ENDCLASS.



CLASS lcl_setup_handler IMPLEMENTATION.

  METHOD zif_system_setup1~run_setup.
    " -----------------------------------------------------------------
    " Hauptmethode: Führt alle Setup-Schritte aus
    " Wird von ZCL_CS1_SETUPCLASS=>init_setup( )->run_setup( ) aufgerufen
    " -----------------------------------------------------------------
    setup_number_range( out ).
    setup_service_table( out ).
  ENDMETHOD.


  METHOD setup_number_range.
    " -----------------------------------------------------------------
    " Wrapper: Erstellt Intervalle für beide Nummernkreis-Objekte
    " ZCS_CUST1 = Customer-IDs, ZCS_IDERR1 = Error-Log-IDs
    " -----------------------------------------------------------------
    create_interval( iv_object = c_obj_cust out = out ).
    create_interval( iv_object = c_obj_err  out = out ).
  ENDMETHOD.


  METHOD create_interval.
    " -----------------------------------------------------------------
    " Legt Intervall '01' von 000001 bis 999999 an, falls es fehlt
    " IMPORTING: iv_object = Nummernkreis-Objektname
    "            out       = Optional für Logging in ADT-Konsole
    " -----------------------------------------------------------------
    DATA: lt_intervals TYPE cl_numberrange_intervals=>nr_interval,
          lv_error     TYPE abap_bool.

    TRY.
        " 1. Bestehende Intervalle lesen
        cl_numberrange_intervals=>read(
          EXPORTING object   = iv_object
          IMPORTING interval = lt_intervals ).

        " 2. Prüfen ob Intervall '01' schon existiert
        IF NOT line_exists( lt_intervals[ nrrangenr = c_range_01 ] ).

          " 3. Intervall definieren: 000001 bis 999999
          lt_intervals = VALUE #( ( nrrangenr  = c_range_01
                                    fromnumber = '000001'
                                    tonumber   = '999999' ) ).

          " 4. Intervall anlegen
          cl_numberrange_intervals=>create(
            EXPORTING interval  = lt_intervals
                      object    = iv_object
            IMPORTING error     = lv_error
                      error_inf = DATA(ls_error_inf) ).

          " 5. Ergebnis ausgeben falls out übergeben wurde
          IF out IS BOUND.
            out->write( COND #( WHEN lv_error IS INITIAL
                                THEN |Objekt { iv_object }: Intervall { c_range_01 } erfolgreich erstellt.|
                                ELSE |Fehler bei { iv_object }: { ls_error_inf-msgnr }| ) ).
          ENDIF.
        ENDIF.
      CATCH cx_number_ranges INTO DATA(lx_error).
        " Fehler bei read/create abfangen
        IF out IS BOUND.
          out->write( |Fehler bei { iv_object }: { lx_error->get_text( ) }| ).
        ENDIF.
    ENDTRY.
  ENDMETHOD.


 METHOD setup_service_table.
    " -----------------------------------------------------------------
    " Setzt Nummernkreis-Level auf 0 zurück wenn Tabelle leer ist
    " Problem: Nach DELETE FROM zcs1_customers steht NRLEVEL noch auf alter Nummer
    " Lösung: Wenn COUNT(*) = 0, dann NRLEVEL = 0 setzen
    " -----------------------------------------------------------------
    DATA: lt_intervals TYPE cl_numberrange_intervals=>nr_interval,
          lt_update    TYPE cl_numberrange_intervals=>nr_interval.

    " 1. Anzahl Datensätze in beiden Tabellen ermitteln
    SELECT COUNT(*) FROM zcs1_customers INTO @DATA(lv_cust_count).
    SELECT COUNT(*) FROM zcs1_import_err INTO @DATA(lv_err_count).

    " 2. Lokale Typen für Prüfungstabelle definieren
    " ABAP Cloud braucht explizite Typen für VALUE-Operator
    TYPES: BEGIN OF ty_reset_check,
             obj   TYPE cl_numberrange_intervals=>nr_object,
             count TYPE i,
           END OF ty_reset_check.
    TYPES tt_reset_checks TYPE STANDARD TABLE OF ty_reset_check WITH EMPTY KEY.

    " 3. Tabelle mit beiden Nummernkreisen + Counts befüllen
    DATA(lt_checks) = VALUE tt_reset_checks(
        ( obj = c_obj_cust count = lv_cust_count )
        ( obj = c_obj_err  count = lv_err_count )
    ).

    " 4. Über beide Nummernkreise iterieren
    LOOP AT lt_checks INTO DATA(ls_check).

      " Nur zurücksetzen wenn Tabelle leer ist
      IF ls_check-count = 0.
        TRY.
            " Aktuelles Intervall lesen
            cl_numberrange_intervals=>read(
              EXPORTING object   = ls_check-obj
              IMPORTING interval = lt_intervals ).

            " Prüfen ob Intervall '01' existiert
            IF line_exists( lt_intervals[ nrrangenr = c_range_01 ] ).
              DATA(ls_line) = lt_intervals[ nrrangenr = c_range_01 ].

              " NRLEVEL = aktueller Stand, PROCIND = 'U' für Update
              ls_line-nrlevel = 0.
              ls_line-procind = 'U'.

              lt_update = VALUE #( ( ls_line ) ).

              " Update: Setzt Level auf 0 zurück
              cl_numberrange_intervals=>update(
                EXPORTING object    = ls_check-obj
                          interval  = lt_update
                IMPORTING error     = DATA(lv_error)
                          error_inf = DATA(ls_error_info) ).

              " Logging
              IF out IS BOUND.
                IF lv_error IS INITIAL.
                  out->write( |Intervall { ls_check-obj } wurde auf 0 zurückgesetzt.| ).
                ELSE.
                  out->write( |Fehler beim Reset von { ls_check-obj }: { ls_error_info-msgnr }| ).
                ENDIF.
              ENDIF.
            ENDIF.
          CATCH cx_number_ranges INTO DATA(lx_error).
            IF out IS BOUND.
              out->write( |Exception bei { ls_check-obj }: { lx_error->get_text( ) }| ).
            ENDIF.
        ENDTRY.
      ELSE.
        " Tabelle nicht leer -> Kein Reset
        IF out IS BOUND.
          out->write( |Intervall { ls_check-obj } nicht zurückgesetzt ({ ls_check-count } Einträge vorhanden).| ).
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
