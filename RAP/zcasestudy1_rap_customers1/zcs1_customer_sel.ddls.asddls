@EndUserText.label: 'Parameter für CancelOrders Action'
define abstract entity ZCS1_CUSTOMER_SEL
{
  @Consumption.valueHelpDefinition: [{ 
    entity: { 
      name: 'ZC_CS1_CUSTOMERS', 
      element: 'Customerid' 
    }
  }]
  @EndUserText.label: 'Kunden-ID'
  key Customerid : zcustomerid1; //abap.char(10);
  
  
  
}
