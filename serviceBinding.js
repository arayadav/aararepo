function initModel() {
	var sUrl = "/sap/opu/odata/sap/ZVENDOR_CDS_CDS/";
	var oModel = new sap.ui.model.odata.ODataModel(sUrl, true);
	sap.ui.getCore().setModel(oModel);
}