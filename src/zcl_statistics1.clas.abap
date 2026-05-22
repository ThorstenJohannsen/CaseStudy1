CLASS zcl_statistics1 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_statistics1.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS zcl_statistics1 IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    SELECT * FROM zcs1_customers INTO TABLE @DATA(lt_customers).
    LOOP AT lt_customers INTO DATA(ls_customer).
      out->write( |Kunde: { ls_customer-customerid } { ls_customer-company }| ).
      out->write( zif_statistics1~average_sales( iv_gjahr = '2024' iv_kunnr = ls_customer-customerid ) ).
      out->write( zif_statistics1~day_sales( iv_gjahr = '2026' ) ).
      out->write( zif_statistics1~max_sales( iv_kunnr = ls_customer-customerid ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_statistics1~average_sales.
    " -----------------------------------------------------------------
    " Berechnet den Durchschnittsumsatz eines Kunden für ein Geschäftsjahr
    " IMPORTING: iv_gjahr = Geschäftsjahr, iv_kunnr = Kundennummer
    " RETURNING: rv_avg   = Durchschnittsumsatz
    " -----------------------------------------------------------------

    " ABAP Cloud: String-Template für Datumsgrenzen YYYYMMDD
    DATA(lv_date_from) = |{ iv_gjahr }0101|.
    DATA(lv_date_to)   = |{ iv_gjahr }1231|.

    " Aggregation direkt auf HANA: AVG ist performanter als Schleife
    " @ vor Host-Variablen ist in ABAP Cloud Pflicht
    SELECT AVG( order_total )
      FROM zcs1_custorders
      WHERE order_date BETWEEN @lv_date_from AND @lv_date_to
        AND customerid = @iv_kunnr
      INTO @rv_avg.


  ENDMETHOD.


  METHOD zif_statistics1~day_sales.
    " -----------------------------------------------------------------
    " Berechnet den durchschnittlichen Tagesumsatz für das laufende GJ
    " Geschäftsjahr ist abhängig vom Land: DE=Kalenderjahr, US=Jul-Jun
    " Zeitraum wird auf heute begrenzt, keine Zukunftswerte
    " RETURNING: rv_day = Durchschnitt pro Tag
    " -----------------------------------------------------------------

    DATA: lv_gjahr     TYPE gjahr,
          lv_first_day TYPE d,
          lv_last_day  TYPE d,
          lv_land      TYPE land1.

    " Systemdatum in ABAP Cloud über Context Info
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    " 1. Geschäftsjahr aus Config holen
    " Annahme: get_zcl_statistics_lv_gjahr gibt string_table zurück
    DATA(lt_gjahr_config) = zcl_cs1_customer_import=>mt_statistics1_lv_gjahr( ).
    " Erste Zeile nehmen, nach GJAHR konvertieren. Fallback = aktuelles Jahr
    lv_gjahr = COND #(
      WHEN lt_gjahr_config IS NOT INITIAL
      THEN CONV gjahr( lt_gjahr_config[ 1 ] )
      ELSE lv_today(4)
    ).

    " 2. Land für GJ-Variante aus Config holen
    DATA(lt_land_config) = zcl_cs1_customer_import=>mt_statistics1_land( ).
    lv_land = VALUE #( lt_land_config[ 1 ] OPTIONAL ).

    " 3. Geschäftsjahresvariante bestimmen
    " US: Fiscal Year 01.07.YYYY bis 30.06.YYYY+1
    " Sonst: Kalenderjahr 01.01.YYYY bis 31.12.YYYY
    IF lv_land = 'US'.
      lv_first_day = |{ lv_gjahr }0701|.
      lv_last_day  = |{ lv_gjahr + 1 }0630|.
    ELSE.
      lv_first_day = |{ lv_gjahr }0101|.
      lv_last_day  = |{ lv_gjahr }1231|.
    ENDIF.

    " 4. Zeitliche Begrenzung: Ende darf nicht in der Zukunft liegen
    IF lv_last_day > lv_today.
      lv_last_day = lv_today.
    ENDIF.

    " 5. Edge Case: Geschäftsjahr hat noch nicht begonnen
    IF lv_first_day > lv_today.
      rv_day = 0.
      RETURN.
    ENDIF.

    " 6. Anzahl Tage im Zeitraum berechnen
    DATA(lv_days) = lv_last_day - lv_first_day + 1.

    " 7. Summe aller Umsätze im Zeitraum + Durchschnitt bilden
    IF lv_days > 0.
      " SUM auf DB-Ebene, nicht in ABAP schleifen
      SELECT SUM( order_total )
        FROM zcs1_custorders
        WHERE order_date BETWEEN @lv_first_day AND @lv_last_day
        INTO @rv_day.

      " Division durch Anzahl Tage für Tagesdurchschnitt
      rv_day = rv_day / lv_days.
    ENDIF.

  ENDMETHOD.


  METHOD zif_statistics1~max_sales.
    " -----------------------------------------------------------------
    " Ermittelt den höchsten Einzelumsatz eines Kunden
    " IMPORTING: iv_kunnr = Kundennummer
    " RETURNING: rv_max   = Maximaler Auftragswert
    " -----------------------------------------------------------------

    " MAX-Aggregation auf HANA - liest nicht alle Sätze
    SELECT MAX( order_total )
      FROM zcs1_custorders
      WHERE customerid = @iv_kunnr
      INTO @rv_max.

  ENDMETHOD.

ENDCLASS.
