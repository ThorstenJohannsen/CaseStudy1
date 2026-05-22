INTERFACE zif_statistics1_04 PUBLIC.

 " Lokale Typdefinition für eine Liste von Kundennummern
  TYPES tt_customers TYPE STANDARD TABLE OF zcustomerid1 WITH EMPTY KEY.

  "! <p class="shorttext synchronized">Durchschnittlicher Umsatz pro Bestellung</p>
  "! @parameter iv_gjahr | Geschäftsjahr
  "! @parameter it_cust_id | Kundennummer/n
  "! @parameter rv_avg | Durchschnitt
  METHODS average_sales
    IMPORTING iv_gjahr TYPE gjahr
                it_cust_id type tt_customers
    RETURNING VALUE(rv_avg) TYPE zorder_total1.

  "! <p class="shorttext synchronized">Maximaler Einzelumsatz pro Kunde</p>
  "! @parameter it_cust_id | Kundennummer/n
  "! @parameter rv_max | Maximaler Umsatz
  METHODS max_sales
    IMPORTING it_cust_id TYPE tt_customers
    RETURNING VALUE(rv_max) TYPE zorder_total1.

  "! <p class="shorttext synchronized">Durchschnittlicher Umsatz pro Tag</p>
  "! @parameter iv_gjahr | Geschäftsjahr
  "! @parameter rv_day | Durchschnitt pro Tag
  METHODS day_sales
    IMPORTING iv_gjahr TYPE gjahr
    RETURNING VALUE(rv_day) TYPE zorder_total1.

ENDINTERFACE.
