@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Suchhilfe für zcs1Cust_orders_R'
@Metadata.ignorePropagatedAnnotations: true
define view entity zcs1Customers_H as select from zcs1_customers
{
    key customerid as Customerid
   
}
