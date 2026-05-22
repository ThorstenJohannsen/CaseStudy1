@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS für Anzahl der Bestellungen'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCS1_l__Z 
as select from zcs1_custorders
association [0..*] to zcs1_custorders 
as _Orders 
on $projection.Customerid = _Orders.customerid

{
    key orderid as Orderid,
    customerid  as Customerid,
    
( count (*) 
//from zcs1_custorders where CustomerID = zcs1_custorders.CustomerID ) 
)as OrderCount
}
group by
   
    customerid,
     orderid

   
