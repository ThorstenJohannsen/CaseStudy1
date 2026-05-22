CLASS zcx_cs1_customer_failed DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check " Statische Prüfung: Caller MUSS CATCH oder RAISING machen
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " --- Interfaces für Nachrichtenbehandlung ---
    INTERFACES if_t100_message.      " Standard T100-Nachrichtenklasse für textid
    INTERFACES if_t100_dyn_msg.      " Dynamische Platzhalter MSGV1-MSGV4
    INTERFACES if_abap_behv_message. " Für RAP: Severity, Ziel-Feld etc.

    " --- Datenfelder für Kontextinfos ---
    " READ-ONLY: Dürfen nur im Constructor gesetzt werden
    DATA filename   TYPE string READ-ONLY. " z.B. Name der CSV-Datei
    DATA mediumdata TYPE string READ-ONLY. " Inhalt Medium für Regex-Fehler
    DATA medium     TYPE string READ-ONLY. " Typ Medium: Phone/Email/Fax
    DATA csv_file   TYPE string READ-ONLY. " Rohdaten der fehlerhaften CSV-Zeile
    DATA header     TYPE string READ-ONLY. " Fehlerhafter Header-Name
    DATA customer   TYPE string READ-ONLY. " Customer-ID falls vorhanden
    DATA company    TYPE string READ-ONLY. " Firmenname bei Validierungsfehler
    DATA parsing    TYPE string READ-ONLY. " Was wurde gerade geparst

    DATA line_number TYPE i READ-ONLY.      " Zeilennummer in CSV
    DATA column_name TYPE string READ-ONLY. " Spaltenname mit Fehler

    " --- T100 Nachrichten-Keys ---
    " attr1-attr4 mappen die DATA-Felder auf MSGV1-MSGV4 für die Message
    CONSTANTS:
      BEGIN OF currencytarget_missing,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF currencytarget_missing,

      BEGIN OF umrechnungsfehler,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF umrechnungsfehler,

      BEGIN OF kd_order_sales_volume,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF kd_order_sales_volume,

      " Regex-Fehler: Nutzt eigene DATA-Felder statt MSGV
      BEGIN OF regularexpression_medium,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '010',
        attr1 TYPE scx_attrname VALUE 'MEDIUM',     " Direkt auf DATA medium
        attr2 TYPE scx_attrname VALUE 'MEDIUMDATA', " Direkt auf DATA mediumdata
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF regularexpression_medium,

      BEGIN OF csv_file_import,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '080',
        attr1 TYPE scx_attrname VALUE 'PARSING',
        attr2 TYPE scx_attrname VALUE 'COLUMN_NAME',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF csv_file_import,

      BEGIN OF invalid_header,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '040',
        attr1 TYPE scx_attrname VALUE 'HEADER',      " ACHTUNG: Leerzeichen vor header war im Original
        attr2 TYPE scx_attrname VALUE 'COLUMN_NAME',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF invalid_header,

      BEGIN OF customer_missing,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '050',
        attr1 TYPE scx_attrname VALUE 'CUSTOMER',    " ACHTUNG: Leerzeichen vor customer war im Original
        attr2 TYPE scx_attrname VALUE 'COLUMN_NAME',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF customer_missing,

      BEGIN OF company_to_long,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '060',
        attr1 TYPE scx_attrname VALUE 'COLUMN_NAME',
        attr2 TYPE scx_attrname VALUE 'FILENAME',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF company_to_long,

      BEGIN OF regularexpression_tele,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '070',
        attr1 TYPE scx_attrname VALUE 'TELE', " Gibt's als DATA nicht - sollte medium sein?
        attr2 TYPE scx_attrname VALUE 'COLUMN_NAME',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF regularexpression_tele.


    " --- Fabrikmethode für RAP ---
    " Erzeugt Exception + setzt Severity + füllt MSGV1-MSGV4
    CLASS-METHODS new_message
      IMPORTING
        i_textid      LIKE if_t100_message=>t100key
        i_severity    TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error
        i_v1          TYPE simple OPTIONAL
        i_v2          TYPE simple OPTIONAL
        i_v3          TYPE simple OPTIONAL
        i_v4          TYPE simple OPTIONAL
      RETURNING
        VALUE(ro_obj) TYPE REF TO zcx_cs1_customer_failed.

    " --- Constructor ---
    " Nimmt alle Kontextinfos entgegen und mappt sie auf READ-ONLY DATA
    METHODS constructor
      IMPORTING
        textid      LIKE if_t100_message=>t100key OPTIONAL
        previous    LIKE previous OPTIONAL
        column_name LIKE column_name OPTIONAL
        filename    LIKE filename OPTIONAL
        medium      LIKE medium OPTIONAL
        mediumdata  LIKE mediumdata OPTIONAL
        csv_file    LIKE csv_file OPTIONAL
        parsing     LIKE parsing OPTIONAL
        customer    LIKE customer OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_cs1_customer_failed IMPLEMENTATION.

  METHOD new_message.
    " 1. Instanz erzeugen - Constructor setzt textid
    ro_obj = NEW zcx_cs1_customer_failed( textid = i_textid ).

    " 2. RAP-Severity setzen: error, warning, info, success
    ro_obj->if_abap_behv_message~m_severity = i_severity.

    " 3. T100-Platzhalter füllen. |{ i_v1 }| wandelt in String
    " Wird nur genutzt wenn CONSTANTS auf IF_T100_DYN_MSG~MSGV1 mappen
    ro_obj->if_t100_dyn_msg~msgv1 = |{ i_v1 }|.
    ro_obj->if_t100_dyn_msg~msgv2 = |{ i_v2 }|.
    ro_obj->if_t100_dyn_msg~msgv3 = |{ i_v3 }|.
    ro_obj->if_t100_dyn_msg~msgv4 = |{ i_v4 }|.
  ENDMETHOD.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    " SUPER aufrufen für previous-Chaining
    super->constructor( previous = previous ).

    " textid an T100-Interface übergeben
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    " Alle Kontextfelder setzen - danach READ-ONLY
    me->filename    = filename.
    me->medium      = medium.
    me->mediumdata  = mediumdata.
    me->csv_file    = csv_file.
    me->header      = header.
    me->customer    = customer.
    me->column_name = column_name.
    me->parsing     = parsing.
  ENDMETHOD.
ENDCLASS.
