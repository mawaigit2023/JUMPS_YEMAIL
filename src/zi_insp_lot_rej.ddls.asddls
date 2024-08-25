@AbapCatalog.sqlViewName: 'ZV_INSP_LOT_REJ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Rejected inspection lot'
define view ZI_INSP_LOT_REJ
  as select from    I_InspectionLot        as lot

    left outer join I_Supplier             as supl on supl.Supplier = lot.Supplier

    left outer join I_InspLotUsageDecision as des  on des.InspectionLot = lot.InspectionLot

{

  key lot.InspectionLot,
      lot.InspectionLotType,
      lot.Plant,
      lot.Material,
      lot.InspectionLotObjectText,
      lot.InspectionLotOrigin,
      lot.MaterialDocument,
      lot.Supplier,
      supl.SupplierName,
      lot.ManufacturingOrder,
      lot.Batch,
      lot.InspectionLotQuantity,
      lot.InspLotQtyToFree,
      lot.InspLotQtyToBlocked,
      des.InspectionLotUsageDecisionCode,
      lot.MatlDocLatestPostgDate,
      lot.PurchasingDocument,
      lot.PurchasingDocumentItem,
      lot.MaterialDocumentYear,
      lot.DeliveryDocument,
      lot.SalesOrder,
      des.InspectionLotUsageDecidedOn

} where des.InspectionLotUsageDecisionCode >= ''
