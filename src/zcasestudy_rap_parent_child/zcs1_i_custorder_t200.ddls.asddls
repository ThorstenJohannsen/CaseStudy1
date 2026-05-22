@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Order T200'
define view entity ZCS1_I_CUSTORDER_T200
  as select from zcs1_custorders
  association to parent ZCS1_I_CUSTOMER_T200 as _Customer on $projection.CustomerID = _Customer.CustomerID
{
  key orderid               as OrderID,
      customerid            as CustomerID,
      order_date            as OrderDate,  // geändert
      @Semantics.amount.currencyCode: 'Currency'
      order_total           as OrderTotal, // geändert
      discount              as Discount,
      info                  as Info,
      status                as Status,
      currency              as Currency,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,  // aus /lrn/s_admin
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,  // aus /lrn/s_admin
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      _Customer
}
