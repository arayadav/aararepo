/* global QUnit */
QUnit.config.autostart = false;

sap.ui.getCore().attachInit(function () {
	"use strict";

	sap.ui.require([
		"Zaara/Zvendor_master_CDS/test/unit/AllTests"
	], function () {
		QUnit.start();
	});
});