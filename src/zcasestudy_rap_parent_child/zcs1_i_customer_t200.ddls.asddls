@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer T200'
define root view entity ZCS1_I_CUSTOMER_T200
  as select from zcs1_customers
  composition [0..*] of ZCS1_I_CUSTORDER_T200 as _Orders
{
  key customerid            as CustomerID,
      salutation            as Salutation,
      last_name             as LastName,  // geändert
      first_name            as FirstName, // geändert
      company               as Company,
      street                as Street,
      city                  as City,
      country               as Country,
      postcode              as PostCode, // geändert
      email                 as Email,
      phone                 as Phone,
      fax                   as Fax,
      currency              as Currency,
      acc_lock              as AccLock,
      last_date             as LastDate,
      change_rate_date      as ChangeRateDate,
      @Semantics.amount.currencyCode: 'Currency'
      sales_volume          as SalesVolume, // geändert
      @Semantics.amount.currencyCode: 'Currency'
      sales_volume_target   as SalesVolumeTarget,
      language              as Language,
      url                   as Url,
      weblogin              as WebLogin,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LastChangedBy,
      local_last_changed_at as LocalLastChangeAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      
      _Orders
}
