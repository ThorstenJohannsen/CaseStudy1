@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer'
@Metadata.ignorePropagatedAnnotations: true
define view entity zcs1customers_r
  as select from zcs1_customers
{
      @EndUserText.label: 'KdNr:'
  key customerid            as Customerid,
      salutation            as Salutation,
      last_name             as LastName,
      first_name            as FirstName,
      company               as Company,
      street                as Street,
      city                  as City,
      country               as Country,
      postcode              as Postcode,
      email                 as Email,
      phone                 as Phone,
      fax                   as Fax,
      acc_lock              as AccLock,
      last_date             as LastDate,
      @Semantics: {amount.currencyCode: 'Currency'}
      sales_volume          as SalesVolume,
      @Semantics: {amount.currencyCode: 'CurrencyTarget'}
      sales_volume_target   as SalesVolumeTarget,
      change_rate_date      as ChangeRateDate,
      url                   as Url,
      currency              as Currency,
      currency_target       as CurrencyTarget,
      language              as Language,
      weblogin              as Weblogin,
      webpw                 as Webpw,
      memo                  as Memo,
      zzvip_zem             as ZzvipZem, // neues Append-Feld
      created_by            as CreatedBy,
      created_at            as CreatedAt,
      local_last_changed_by as LocalLastChangedBy,
      local_last_changed_at as LocalLastChangedAt,
      last_changed_at       as LastChangedAt
}
