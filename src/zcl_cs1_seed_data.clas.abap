" Tasks Sebastian
" Statisctic service einbauen
"

CLASS zcl_cs1_seed_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Interface für ADT Run-Konsole F9
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
    " --- Seed-Methoden für alle Tabellen ---
    METHODS seed_customers_csv
      IMPORTING iv_out TYPE REF TO if_oo_adt_classrun_out.
    METHODS seed_orders
      IMPORTING iv_out TYPE REF TO if_oo_adt_classrun_out.
    METHODS seed_statistic
      IMPORTING iv_out TYPE REF TO if_oo_adt_classrun_out.
    METHODS seed_service
      IMPORTING iv_out TYPE REF TO if_oo_adt_classrun_out.
    METHODS seed_zipcity
      IMPORTING iv_out TYPE REF TO if_oo_adt_classrun_out.

    " --- Konstanten für Testdaten ---
    " In ABAP Cloud kein sy-mandt mehr, aber bei Customizing-Tabellen ok
    CONSTANTS: gc_client TYPE mandt   VALUE '100',
               gc_date   TYPE d       VALUE '20260429',
               gc_user   TYPE syuname VALUE 'SEED'.
ENDCLASS.



CLASS zcl_cs1_seed_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " -----------------------------------------------------------------
    " Hauptmethode für F9 in ADT
    " Führt alle Seed-Methoden nacheinander aus
    " Reihenfolge wichtig: erst Config-Tabellen, dann Stammdaten
    " -----------------------------------------------------------------

    DELETE FROM zcs1_import_err.

    seed_customers_csv( out ). " CSV-Import + Customers
    seed_orders( out ).        " Bestellungen - braucht Customers
    seed_statistic( out ).     " Customizing welche Klasse/Interface
    seed_service( out ).       " Config für Regex, CSV-Parser etc.
    seed_zipcity( out ).       " PLZ-Stammdaten



  ENDMETHOD.


  METHOD seed_service.
    " -----------------------------------------------------------------
    " Befüllt ZCS1_SERVICE1 mit Config-Werten
    " Diese Tabelle steuert Regex, CSV-Trenner, Defaults etc.
    " active = abap_false -> user_value wird genommen
    " active = abap_true  -> default_value wird genommen
    " -----------------------------------------------------------------
    DELETE FROM zcs1_service1.

    " MODIFY = INSERT oder UPDATE je nachdem ob Key existiert
    MODIFY zcs1_service1 FROM TABLE @( VALUE #(
      " --- CSV-Parser Config ---
      ( id = 'mt_split_csv_line_replace1' active = abap_false user_value = `^""|^"|"$|""$###SC###` default_value = `^""|^"|"$|""$ ###SC###` created_by = gc_user )
      ( id = 'mt_split_csv_line_replace2' active = abap_false user_value = `^ | $###SC###`         default_value = `^ | $###SC###` created_by = gc_user )
      ( id = 'mt_split_csv_line_replace3' active = abap_false user_value = `^\s+|\s+$###SC###`     default_value = `^\s+|\s+$###SC###` created_by = gc_user )
      ( id = 'mt_split_csv_line_sep'      active = abap_false user_value = `;`                     default_value = `;` created_by = gc_user )

      " --- Validierungs-Regex ---
      ( id = 'mt_is_email_valid_regex'    active = abap_false user_value = `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$` default_value = `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$` created_by = gc_user )
      ( id = 'mt_is_tel_valid_lv_clean'   active = abap_false user_value = `(?!^\+)[^\d]###SC###`  default_value = `(?!^\+)[^\d]###SC###` created_by = gc_user )
      ( id = 'mt_is_tel_valid_lv_regex_1' active = abap_false user_value = `^\+?\d{7,15}$`         default_value = `^\+?\d{7,15}$` created_by = gc_user )
      ( id = 'mt_is_tel_valid_lv_regex_2' active = abap_false user_value = `^\+[1-9]\d{7,14}$`     default_value = `^\+[1-9]\d{7,14}$` created_by = gc_user )

      " --- CSV-Merge Config ---
      ( id = 'mt_parse_customers_replace1' active = abap_false user_value = `[^\d]###SC###`        default_value = `[^\d]   ###SC###` created_by = gc_user )
      ( id = 'mt_parse_customers_replace2' active = abap_false user_value = `^0(\d+)###SC###+49$1` default_value = `^0(\d+) ###SC###+49$1` created_by = gc_user )

      " --- Import-Defaults ---
      ( id = 'mt_import_customers_webpass'  active = abap_false user_value = `Welcome1!` default_value = `Welcome1!` created_by = gc_user )
      ( id = 'mt_import_customers_acc_lock' active = abap_false user_value = `X`         default_value = ` `    created_by = gc_user )
      ( id = 'mt_import_customers_language' active = abap_false user_value = `D`         default_value = `D`    created_by = gc_user )
      ( id = 'mt_import_customers_country'  active = abap_false user_value = `DE`        default_value = `DE`   created_by = gc_user )
      ( id = 'mt_import_customers_curr'     active = abap_false user_value = `EUR`       default_value = `EUR`  created_by = gc_user )
      ( id = 'mt_import_customers_curr_t'   active = abap_false user_value = `USD`       default_value = `USD`  created_by = gc_user )

      " --- Statistik Config ---
      ( id = 'mt_statistics1_land'          active = abap_false user_value = `DE`        default_value = `DE`   created_by = gc_user )
      ( id = 'mt_statistics1_lv_gjahr'      active = abap_false user_value = `2026`      default_value = `2026` created_by = gc_user )
      ) ).

    IF sy-subrc = 0.
      COMMIT WORK. " In ABAP Cloud eigentlich nicht nötig, aber schadet nicht
    ENDIF.

    " Kontrolle: Anzahl prüfen
    SELECT * FROM zcs1_service1 INTO TABLE @DATA(lt_check).
    iv_out->write( |Service1 Einträge: { lines( lt_check ) }| ).
  ENDMETHOD.


  METHOD seed_customers_csv.
    " -----------------------------------------------------------------
    " Löscht alte Daten und startet CSV-Import
    " Nutzt ZCL_CS1_CUSTOMER_IMPORT -> liest ZTL_00_CASESTUDY
    " -----------------------------------------------------------------
    DELETE FROM zcs1_customers.
    iv_out->write( |Customers gelöscht: { sy-dbcnt }| ).

    DELETE FROM zcs1_import_err.
    iv_out->write( |Import Errors gelöscht: { sy-dbcnt }| ).

    " Setup + Import starten. Import liest aus ZTL_00_CASESTUDY
    DATA(lo_import) = NEW zcl_cs1_customer_import( ).
    lo_import->main_programm( iv_out = iv_out ).
    iv_out->write( |Customers eingefügt: { sy-dbcnt }| ).
  ENDMETHOD.


  METHOD seed_statistic.
    " -----------------------------------------------------------------
    " Customizing für dynamische Klassenfindung
    " ZCL_STATISTICS1_04 liest hier welche Klasse/Interface aktiv ist
    " DEFAULT0 = Produktiv, Rest = Testvarianten
    " -----------------------------------------------------------------
    DELETE FROM zcs1_statistic.
    INSERT zcs1_statistic FROM TABLE @( VALUE #(
      ( client = gc_client stat_id = 'DEFAULT0' interface_name = 'ZIF_STATISTICS1'     class_name = 'ZCL_STATISTICS1'     active = abap_true  created_by = gc_user )
      ( client = gc_client stat_id = 'DEFAULT1' interface_name = 'ZIF_STATISTICS1_ERR' class_name = 'ZCL_STATISTICS1'     active = abap_false created_by = gc_user )
      ( client = gc_client stat_id = 'DEFAULT2' interface_name = 'ZIF_STATISTICS1'     class_name = 'ZCL_STATISTICS1_ERR' active = abap_false created_by = gc_user )
      ( client = gc_client stat_id = 'DEFAULT3' interface_name = 'ZIF_STATISTICS1_ERR' class_name = 'ZCL_STATISTICS1_ERR' active = abap_false created_by = gc_user )
      ( client = gc_client stat_id = 'DEFAULT4' interface_name = 'ZIF_STATISTICS1'     class_name = 'ZCL_STATISTICS1_04'  active = abap_false created_by = gc_user ) ) ).
    iv_out->write( |Statistic eingefügt: { sy-dbcnt }| ).
  ENDMETHOD.


  METHOD seed_orders.
    " -----------------------------------------------------------------
    " Testbestellungen für Statistik-Auswertung
    " Verschiedene Status BA/BB/BN/BO für Filter-Tests
    " Alle auf gc_date = 2026-04-29
    " -----------------------------------------------------------------
    DELETE FROM zcs1_custorders.
    iv_out->write( |Orders gelöscht: { sy-dbcnt }| ).

    INSERT zcs1_custorders FROM TABLE @( VALUE #(
      ( client = gc_client orderid = '000006' customerid = '000001' order_date = gc_date order_total = '4200.00' discount = '1.00' status = 'BA' created_by = gc_user )
      ( client = gc_client orderid = '000007' customerid = '000001' order_date = gc_date order_total = '2800.00' discount = '1.00' status = 'BB' created_by = gc_user )
      ( client = gc_client orderid = '000008' customerid = '000001' order_date = gc_date order_total = '4200.00' discount = '1.00' status = 'BN' created_by = gc_user )
      ( client = gc_client orderid = '000009' customerid = '000001' order_date = gc_date order_total = '2800.00' discount = '1.00' status = 'BO' created_by = gc_user )
      ( client = gc_client orderid = '000010' customerid = '000002' order_date = gc_date order_total = '7100.00' discount = '3.00' status = 'BO' created_by = gc_user )
      ( client = gc_client orderid = '000011' customerid = '000007' order_date = gc_date order_total = '1500.00' discount = '1.00' status = 'BN' created_by = gc_user )
      ( client = gc_client orderid = '000012' customerid = '000007' order_date = gc_date order_total = '2300.00' discount = '2.00' status = 'BA' created_by = gc_user )
      ( client = gc_client orderid = '000013' customerid = '000010' order_date = gc_date order_total = '999.00'  discount = '1.00' status = 'BA' created_by = gc_user )
      ( client = gc_client orderid = '000014' customerid = '000019' order_date = gc_date order_total = '4500.00' discount = '2.00' status = 'BO' created_by = gc_user )
      ( client = gc_client orderid = '000015' customerid = '000019' order_date = gc_date order_total = '1200.00' discount = '1.00' status = 'BA' created_by = gc_user )
      ( client = gc_client orderid = '000016' customerid = '000020' order_date = gc_date order_total = '6200.00' discount = '3.00' status = 'BA' created_by = gc_user )
      ( client = gc_client orderid = '000017' customerid = '000022' order_date = gc_date order_total = '3100.00' discount = '1.00' status = 'BA' created_by = gc_user )
      ( client = gc_client orderid = '000018' customerid = '000030' order_date = gc_date order_total = '8000.00' discount = '4.00' status = 'BN' created_by = gc_user )
      ( client = gc_client orderid = '000019' customerid = '000033' order_date = gc_date order_total = '1750.00' discount = '1.00' status = 'BO' created_by = gc_user )
      ( client = gc_client orderid = '000020' customerid = '000034' order_date = gc_date order_total = '5000.00' discount = '2.00' status = 'BN' created_by = gc_user )
      ( client = gc_client orderid = '000021' customerid = '000034' order_date = gc_date order_total = '2200.00' discount = '1.00' status = 'BB' created_by = gc_user ) ) ).

    iv_out->write( |Orders eingefügt: { sy-dbcnt }| ).
  ENDMETHOD.


  METHOD seed_zipcity.
    " -----------------------------------------------------------------
    " PLZ-Stammdaten für deutsche Großstädte
    " Wird für Adressvalidierung genutzt
    " -----------------------------------------------------------------
    DELETE FROM zcs1_zipcity.

    " MODIFY = INSERT oder UPDATE, sicherer als INSERT
    MODIFY zcs1_zipcity FROM TABLE @( VALUE #(
      ( client = sy-mandt postcode = '10115' city = 'Berlin' created_by = gc_user )
      ( client = sy-mandt postcode = '20095' city = 'Hamburg' created_by = gc_user )
      ( client = sy-mandt postcode = '80331' city = 'München' created_by = gc_user )
      ( client = sy-mandt postcode = '50667' city = 'Köln' created_by = gc_user )
      ( client = sy-mandt postcode = '60311' city = 'Frankfurt am Main' created_by = gc_user )
      ( client = sy-mandt postcode = '70173' city = 'Stuttgart' created_by = gc_user )
      ( client = sy-mandt postcode = '40213' city = 'Düsseldorf' created_by = gc_user )
      ( client = sy-mandt postcode = '44135' city = 'Dortmund' created_by = gc_user )
      ( client = sy-mandt postcode = '45127' city = 'Essen' created_by = gc_user )
      ( client = sy-mandt postcode = '04109' city = 'Leipzig' created_by = gc_user )
      ( client = sy-mandt postcode = '28195' city = 'Bremen' created_by = gc_user )
      ( client = sy-mandt postcode = '01067' city = 'Dresden' created_by = gc_user )
      ( client = sy-mandt postcode = '30159' city = 'Hannover' created_by = gc_user )
      ( client = sy-mandt postcode = '90402' city = 'Nürnberg' created_by = gc_user )
      ( client = sy-mandt postcode = '47051' city = 'Duisburg' created_by = gc_user )
      ( client = sy-mandt postcode = '44787' city = 'Bochum' created_by = gc_user )
      ( client = sy-mandt postcode = '42103' city = 'Wuppertal' created_by = gc_user )
      ( client = sy-mandt postcode = '33602' city = 'Bielefeld' created_by = gc_user )
      ( client = sy-mandt postcode = '53111' city = 'Bonn' created_by = gc_user )
      ( client = sy-mandt postcode = '48143' city = 'Münster' created_by = gc_user )
      ( client = sy-mandt postcode = '76133' city = 'Karlsruhe' created_by = gc_user )
      ( client = sy-mandt postcode = '68159' city = 'Mannheim' created_by = gc_user )
      ( client = sy-mandt postcode = '86150' city = 'Augsburg' created_by = gc_user )
      ( client = sy-mandt postcode = '65183' city = 'Wiesbaden' created_by = gc_user )
      ( client = sy-mandt postcode = '39104' city = 'Magdeburg' created_by = gc_user )
      ( client = sy-mandt postcode = '22145' city = 'Hamburg' created_by = gc_user )
      ( client = sy-mandt postcode = '41061' city = 'Mönchengladbach' created_by = gc_user )
      ( client = sy-mandt postcode = '57072' city = 'Siegen' created_by = gc_user )
      ( client = sy-mandt postcode = '24103' city = 'Kiel' created_by = gc_user )
      ( client = sy-mandt postcode = '66111' city = 'Saarbrücken' created_by = gc_user )
      ( client = sy-mandt postcode = '93047' city = 'Regensburg' created_by = gc_user ) ) ).

    COMMIT WORK.
    iv_out->write( |Zipcodes eingefügt: { sy-dbcnt }| ).
  ENDMETHOD.
ENDCLASS.
