@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Order Projection T200'
@Metadata.allowExtensions: true
define view entity ZCS1_C_CUSTORDER_T200
  as projection on ZCS1_I_CUSTORDER_T200
{
  key OrderID,
      CustomerID,
      OrderDate,
      OrderTotal,
      Currency,
      Discount,
      Info,
      Status,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      
      _Customer : redirected to parent ZCS1_C_CUSTOMER_T200
}
