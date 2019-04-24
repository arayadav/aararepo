sap.ui.define(["sap/ui/core/mvc/Controller"], function (Controller) {
	"use strict";
	return Controller.extend("Zaara.Zvendor_master_CDS.controller.View1", {
		onInit: function () {},
		/**
		 *@memberOf Zaara.Zvendor_master_CDS.controller.View1
		 */
		get_details: function (oEvent) {
			var Lifnr = this.getView().byId("ivendornum").getValue();
			var url = "/sap/opu/odata/sap/ZVENDOR_DETAILS_SRV/zvendor_testSet(Lifnr='" + Lifnr + "')";
			var oModel = new sap.ui.model.json.JSONModel();
			oModel.loadData(url, null, false);
			var data = oModel.oData.d;
			this.getView().byId("ovendname1").setValue(data.Name1);
			this.getView().byId("ovendland1").setValue(data.Land1);
		}
	});
});