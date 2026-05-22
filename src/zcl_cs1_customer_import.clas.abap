CLASS zcl_cs1_customer_import DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " Interfaces für verschiedene Aufrufkontexte
    INTERFACES if_oo_adt_classrun.      " ADT Run-Konsole F9
    INTERFACES if_apj_dt_exec_object.   " Application Job Template Definition
    INTERFACES if_apj_rt_exec_object.   " Application Job Execution Runtime
    INTERFACES zif_cs1_validation.      " Externes Validierungs-Interface


    " Hauptprogramm - kann von ADT oder Job aufgerufen werden
    METHODS main_programm
      IMPORTING iv_out TYPE REF TO if_oo_adt_classrun_out OPTIONAL.

    " --- Getter für Config-Werte aus ZCS1_SERVICE1 ---
    " Gibt Land für Statistik zurück, z.B. DE/US
    CLASS-METHODS mt_statistics1_land
      RETURNING VALUE(rt_gjahr) TYPE string_table.

    " Gibt Geschäftsjahr für Statistik zurück, z.B. 2026
    CLASS-METHODS mt_statistics1_lv_gjahr
      RETURNING VALUE(rt_gjahr) TYPE string_table.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_cs1_customer_import IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " -----------------------------------------------------------------
    " Aufruf aus ADT Run-Konsole mit Output-Objekt
    " Gibt Systeminfos aus und startet dann main_programm
    " -----------------------------------------------------------------

    " ACHTUNG: sy-saprl ist in ABAP Cloud veraltet, wirft Warnung
    " Besser: cl_abap_context_info=>get_system_release( )
    out->write( |Release: { sy-saprl  }| ). "cl_abap_context_info=>get_system_release( ) not work
    out->write( |Datum: { cl_abap_context_info=>get_system_date( ) DATE = USER }| ).
    out->write( |Zeit: { cl_abap_context_info=>get_system_time( ) TIME = USER }| ).
    out->write( |User: { cl_abap_context_info=>get_user_technical_name( ) }| ).
    out->write( |Mandant: { sy-mandt }| ). " sy-mandt ist noch erlaubt
    out->write( |Sprache: { sy-langu }| ). " sy-langu ist noch erlaubt

    main_programm( iv_out = out ).
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    " -----------------------------------------------------------------
    " Aufruf aus Application Job ohne Output
    " Läuft im Hintergrund, iv_out ist initial
    " -----------------------------------------------------------------
    main_programm( ).
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    " -----------------------------------------------------------------
    " Keine Job-Parameter nötig für diesen Import
    " Job läuft immer mit gleichen Settings
    " -----------------------------------------------------------------
    CLEAR et_parameter_def.
    CLEAR et_parameter_val.
  ENDMETHOD.


  METHOD main_programm.
    " -----------------------------------------------------------------
    " Orchestriert den kompletten Import-Prozess
    " 1. Setup, 2. CSV lesen, 3. Validieren, 4. DB-Write, 5. Fehler, 6. BAdI
    " -----------------------------------------------------------------
    TRY.
        iv_out->write( '          main_programm          ' ).
        " Schritt 1: Setup ausführen - schreibt ZCS1_SERVICE1, ZTL_00_CASESTUDY etc.
        " Muss VOR dem Erzeugen von lcl_customer_import laufen
        zcl_cs1_setupclass=>init_setup( )->run_setup( iv_out ).

        " Schritt 2: Importer erzeugen
        " constructor -> refresh_service -> lädt CLASS-DATA aus ZCS1_SERVICE1
        DATA(lo_csv_processor) = NEW lcl_customer_import( ).

        " Schritt 3: CSV parsen und validieren
        lo_csv_processor->parse_csv( ).
        lo_csv_processor->parse_customers( ).
        iv_out->write( lo_csv_processor->return_table( ) ).

        " Schritt 4: In DB schreiben
        lo_csv_processor->import_customers( ).
        iv_out->write( '-------- return_table ----------' ).
        iv_out->write( lo_csv_processor->return_table( ) ).

        " Schritt 5: Fehler/Neukunden sammeln
        lo_csv_processor->new_customer_tab( ).
        iv_out->write( '-------- return_new_customer_tab_table ----------' ).
        iv_out->write( lo_csv_processor->return_new_customer_tab_table( ) ).

        lo_csv_processor->email_err_tab( ).
        iv_out->write( '--------  Email_Tele_Telfax_Error ----------' ).
        iv_out->write( lo_csv_processor->email_tele_telfax_error( ) ).

        lo_csv_processor->company_err_tab( ).
        iv_out->write( '-------- return_err_table ----------' ).
        iv_out->write( lo_csv_processor->return_err_table( ) ).

        " Schritt 6: BAdI für Custom-Logic aufrufen
        lo_csv_processor->call_badi( ).

      CATCH cx_sy_open_sql_db cx_uuid_error INTO DATA(lx_db_err).
        iv_out->write( |DB-Fehler: { lx_db_err->get_text( ) }| ).

      CATCH zcx_cs1_customer_failed INTO DATA(lx_error).
        iv_out->write( |Fehler aufgetreten:| ).
        iv_out->write( lx_error->get_text( ) ).
        iv_out->write( |Datei: { lx_error->filename } Zeile: { lx_error->line_number }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_cs1_validation~is_email_valid.
    " -----------------------------------------------------------------
    " Interface-Methode: Prüft E-Mail über Regex aus Config
    " Lazy-Loading: Lädt Config nur wenn noch nicht geladen
    " -----------------------------------------------------------------
    lcl_customer_import=>refresh_service( ).
    rv_valid = lcl_customer_import=>is_email_valid( iv_email = CONV string( iv_email ) ).
  ENDMETHOD.


  METHOD zif_cs1_validation~is_phone_valid.
    " -----------------------------------------------------------------
    " Interface-Methode: Prüft Telefon über Regex aus Config
    " -----------------------------------------------------------------
    lcl_customer_import=>refresh_service( ).
    rv_valid = lcl_customer_import=>is_tel_valid( iv_tel = CONV string( iv_phone ) ).
  ENDMETHOD.


  METHOD zif_cs1_validation~is_fax_valid.
    " -----------------------------------------------------------------
    " Interface-Methode: Prüft Fax über Regex aus Config
    " Nutzt gleiche Regex wie Telefon
    " -----------------------------------------------------------------
    lcl_customer_import=>refresh_service( ).
    rv_valid = lcl_customer_import=>is_fax_valid( iv_tel = CONV string( iv_fax ) ).
  ENDMETHOD.


  METHOD zif_cs1_validation~latenumbering.
    " -----------------------------------------------------------------
    " Interface-Methode: Holt nächste Customer-ID aus Nummernkreis
    " Fängt Nummernkreis-Fehler ab und gibt leere ID zurück
    " -----------------------------------------------------------------
    TRY.
        rv_id = lcl_customer_import=>get_next_customer_id( ).
      CATCH cx_number_ranges INTO DATA(lx_nr).
        " Im Fehlerfall leere ID zurückgeben
        CLEAR rv_id.
    ENDTRY.
  ENDMETHOD.


  METHOD mt_statistics1_land.
    " -----------------------------------------------------------------
    " Getter für Land aus ZCS1_SERVICE1
    " FEHLER: Endlosrekursion! Ruft sich selbst auf
    " -----------------------------------------------------------------
    " Richtig: Direkt aus lcl_customer_import holen
    rt_gjahr = lcl_customer_import=>mt_statistics1_land.
    IF rt_gjahr IS INITIAL.
      lcl_customer_import=>refresh_service( ).
      rt_gjahr = lcl_customer_import=>mt_statistics1_land.
    ENDIF.
    " FALSCH WAR: rt_gjahr = zcl_cs1_customer_import=>mt_statistics1_land( ).
  ENDMETHOD.


  METHOD mt_statistics1_lv_gjahr.
    " -----------------------------------------------------------------
    " Getter für Geschäftsjahr aus ZCS1_SERVICE1
    " FEHLER: Endlosrekursion! Ruft sich selbst auf
    " -----------------------------------------------------------------
    " Richtig: Direkt aus lcl_customer_import holen
    rt_gjahr = lcl_customer_import=>mt_statistics1_lv_gjahr.
    IF rt_gjahr IS INITIAL.
      lcl_customer_import=>refresh_service( ).
      rt_gjahr = lcl_customer_import=>mt_statistics1_lv_gjahr.
    ENDIF.
    " FALSCH WAR: rt_gjahr = zcl_cs1_customer_import=>mt_statistics1_lv_gjahr( ).
  ENDMETHOD.


ENDCLASS.
