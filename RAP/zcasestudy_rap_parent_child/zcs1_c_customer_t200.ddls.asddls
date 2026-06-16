@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Projection T200'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZCS1_C_CUSTOMER_T200
provider contract transactional_query
  as projection on ZCS1_I_CUSTOMER_T200
{
  key CustomerID,
      @Search.defaultSearchElement: true
      LastName,
      @Search.defaultSearchElement: true
      FirstName,
      Company,
      City,
      Country,
      Email,
      Phone,
      Currency,
      SalesVolume,
      Language,
      Url,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,         

      _Orders : redirected to composition child ZCS1_C_CUSTORDER_T200
}
