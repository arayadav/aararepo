@AbapCatalog.sqlViewName: 'ZLFA1_TEST'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'CDS View for vendor'
define view ZVendor_test 
with parameters P_LIFNR:lifnr
as select from lfa1 {
key lfa1.lifnr,
lfa1.land1,
lfa1.name1
}
where lfa1.lifnr = $parameters.P_LIFNR
