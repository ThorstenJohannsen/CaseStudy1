@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Liste der Umsätze pro Kunde'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCS1_CSTRDR000_PpC as select from zcs1_cstrdr000_d as O
left outer join zcs1_customers as C
on O.customerid = C.customerid
{

C.first_name, 
C.last_name,
   @Semantics.amount.currencyCode: 'Currency'
   sum(O.ordertotal ) as customersordertotal,
   O.currency as Currency
   }
group by
    C.first_name,
    C.last_name,
    O.currency


