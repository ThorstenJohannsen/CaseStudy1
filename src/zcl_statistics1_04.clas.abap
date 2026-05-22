CLASS zcl_statistics1_04 DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_statistics1_04.
    INTERFACES if_oo_adt_classrun.
    INTERFACES zif_statistics1.
    METHODS statistics.
ENDCLASS.



CLASS zcl_statistics1_04 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    " -----------------------------------------------------------------
    " 1. Customizing lesen: Welche Klasse/Interface soll genutzt werden?
    " -----------------------------------------------------------------
    SELECT SINGLE FROM zcs1_statistic
      FIELDS class_name, interface_name
      WHERE stat_id = 'DEFAULT'
        AND active   = @abap_true
      INTO @DATA(ls_stat).

    IF sy-subrc <> 0.
      out->write( 'Kein Customizing gefunden.' ).
      RETURN.
    ENDIF.

    TRY.
        " -----------------------------------------------------------------
        " 2. Variablen für Methodenaufrufe vorbelegen
        " -----------------------------------------------------------------
        DATA: lv_max        TYPE zorder_total1,
              lv_avg        TYPE zorder_total1,
              lv_day        TYPE zorder_total1,
              lv_gjahr      TYPE gjahr          VALUE '2026',
              lv_customerid TYPE zcustomerid1   VALUE '000022'.

        " =================================================================
        " DER DYNAMISCHE TEIL MIT RTTS/RTTC - ABAP Cloud konform
        " =================================================================

        " -----------------------------------------------------------------
        " 3.1 Instanz der Klasse erzeugen
        " CREATE OBJECT mit dynamischem Typnamen aus Customizing
        " -----------------------------------------------------------------
        DATA lo_object TYPE REF TO object.
        TRY.
            CREATE OBJECT lo_object TYPE (ls_stat-class_name).
          CATCH cx_sy_create_object_error.
            out->write( |Klasse konnte nicht instanziiert werden: { ls_stat-class_name }| ).
            RETURN.
        ENDTRY.

        " -----------------------------------------------------------------
        " 3.2 RTTS: Interface-Typbeschreibung holen und validieren
        " Prüfen ob ls_stat-interface_name wirklich ein Interface ist
        " -----------------------------------------------------------------
        DATA lo_intf_descr TYPE REF TO cl_abap_objectdescr.

        TRY.
            " Typbeschreibung über Namen holen
            DATA(lo_generic_descr) = cl_abap_typedescr=>describe_by_name( ls_stat-interface_name ).

            " Validierung: Existiert und ist es ein Interface?
            IF lo_generic_descr IS NOT BOUND OR
               lo_generic_descr->kind <> cl_abap_typedescr=>kind_intf.
              out->write( |Der Name ist kein gültiges Interface: { ls_stat-interface_name }| ).
              RETURN.
            ENDIF.

            " Sicherer Cast auf Object-/Interface-Beschreibung
            lo_intf_descr = CAST cl_abap_objectdescr( lo_generic_descr ).

          CATCH cx_sy_move_cast_error.
            out->write( |Interface existiert nicht oder Typkonflikt: { ls_stat-interface_name }| ).
            RETURN.
        ENDTRY.

        " -----------------------------------------------------------------
        " 3.3 RTTS: Prüfen ob Methode AVERAGE_SALES im Interface existiert
        " Verhindert Laufzeitfehler bei CALL METHOD
        " -----------------------------------------------------------------
        READ TABLE lo_intf_descr->methods
          WITH KEY name = 'AVERAGE_SALES'
          TRANSPORTING NO FIELDS.

        IF sy-subrc <> 0.
          out->write( 'Methode AVERAGE_SALES fehlt im Interface!' ).
          RETURN.
        ENDIF.

        " -----------------------------------------------------------------
        " 3.4 RTTC: Dynamischen Referenztyp auf das Interface erzeugen
        " Erzeugt zur Laufzeit den Typ 'REF TO (ls_stat-interface_name)'
        " -----------------------------------------------------------------
        DATA(lo_ref_descr) = cl_abap_refdescr=>create( lo_intf_descr ).

        " -----------------------------------------------------------------
        " 3.5 RTTC: Datenobjekt vom Typ 'REF TO (Interface)' generieren
        " CREATE DATA mit HANDLE erzeugt eine Datenreferenz auf den Typ
        " -----------------------------------------------------------------
        DATA lo_dyn_intf_ref TYPE REF TO data.
        CREATE DATA lo_dyn_intf_ref TYPE HANDLE lo_ref_descr.

        " -----------------------------------------------------------------
        " 3.6 Feldsymbol zuweisen und Downcast ausführen
        " <lo_intf_ptr> ist jetzt vom Typ 'REF TO (ls_stat-interface_name)'
        " ?= Cast prüft ob lo_object das Interface implementiert
        " -----------------------------------------------------------------
        ASSIGN lo_dyn_intf_ref->* TO FIELD-SYMBOL(<lo_intf_ptr>).

        TRY.
            <lo_intf_ptr> ?= lo_object.
          CATCH cx_sy_move_cast_error.
            out->write( |Die Klasse { ls_stat-class_name } implementiert das Interface { ls_stat-interface_name } nicht.| ).
            RETURN.
        ENDTRY.

        " -----------------------------------------------------------------
        " 3.7 Echte Objektreferenz für Methodenaufruf erzeugen
        " In ABAP Cloud kann man über Datenreferenzen keine Methoden aufrufen
        " Deshalb Umweg über TYPE REF TO object
        " -----------------------------------------------------------------
        DATA lo_stat_if TYPE REF TO object.
        lo_stat_if = <lo_intf_ptr>.

        " =================================================================
        " 4. DYNAMISCHE METHODENAUFRUFE
        " =================================================================

        " Methodenname dynamisch zusammenbauen: 'INTERFACE~METHODE'
        DATA(lv_method_name) = |{ ls_stat-interface_name }~AVERAGE_SALES|.

        " Aufruf über (lv_method_name) - Klammern = dynamischer Aufruf
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_gjahr = lv_gjahr
            iv_kunnr = lv_customerid
          RECEIVING
            rv_avg   = lv_avg.

        lv_method_name = |{ ls_stat-interface_name }~MAX_SALES|.
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_kunnr = lv_customerid
          RECEIVING
            rv_max   = lv_max.

        lv_method_name = |{ ls_stat-interface_name }~DAY_SALES|.
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_gjahr = lv_gjahr
          RECEIVING
            rv_day   = lv_day.

        " -----------------------------------------------------------------
        " 5. Ausgabe der Ergebnisse
        " -----------------------------------------------------------------
        out->write( |Klasse: { ls_stat-class_name } / Interface: { ls_stat-interface_name }| ).
        out->write( |Average Sales: { lv_avg }| ).
        out->write( |Max Sales: { lv_max }| ).
        out->write( |Day Sales: { lv_day }| ).

      " =================================================================
      " FEHLERBEHANDLUNG
      " =================================================================
      CATCH cx_sy_create_object_error INTO DATA(lx_create).
        out->write( |Fehler beim Erzeugen der Klasse: { lx_create->get_text( ) }| ).

      CATCH cx_sy_create_data_error.
        out->write( |Fehler: Interface { ls_stat-interface_name } existiert nicht.| ).

      CATCH cx_sy_move_cast_error.
        out->write( |Fehler: Klasse { ls_stat-class_name } implementiert { ls_stat-interface_name } nicht.| ).

      CATCH cx_sy_dyn_call_error INTO DATA(lx_call).
        out->write( |Fehler beim Methodenaufruf (Methode evtl. nicht vorhanden): { lx_call->get_text( ) }| ).

      CATCH cx_root INTO DATA(lx_root).
        out->write( |Unerwarteter Fehler: { lx_root->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD statistics.
    " Platzhalter - aktuell nicht verwendet
  ENDMETHOD.


  METHOD zif_statistics1~max_sales.
    " Statische Implementierung für Direktaufruf ohne Dynamik
    " HANA Cloud: @ vor Host-Variablen bei OpenSQL
    SELECT MAX( order_total )
      FROM zcs1_custorders
      WHERE customerid = @iv_kunnr
      INTO @rv_max.
  ENDMETHOD.
ENDCLASS.
