@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Liste der Umsätze pro Kunde'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCS1CUST_ORDERS_PPC 
  as select from zcs1_custorders
{
  key customerid                      as Customerid,
      @Semantics.amount.currencyCode: 'Currency'
      sum(order_total)                as OrderTotal,      // Summe pro Kunde
      @Semantics.amount.currencyCode: 'Currency'  
      max(order_total)                as MaxOrderTotal,   // Maximalumsatz pro Kunde
      @Semantics.amount.currencyCode: 'Currency'
        sum ( cast( (cast(discount as abap.dec(15,2)) * cast(order_total as abap.dec(15,2))) / 100  as abap.dec(15,2) ) ) as DiscountAmounttotal,    // Summe Rabatt pro Kunde
      currency                        as Currency,
      count(*)                        as OrderCount,       // Anzahl Bestellungen
      sum(discount)                   as DiscountSum
  
     
}
group by
  customerid,
  currency
