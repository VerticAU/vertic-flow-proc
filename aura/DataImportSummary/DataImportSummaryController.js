({
    handleDownloadErrorReport: function (cmp, event, helper) {

        let summary = cmp.get('v.meta.dto.importSummary');

        let failedResults = summary.results.filter(function (result) {
            return result.isValid !== true;
        });

        let rows = failedResults.map(function (result) {
            let CSVData = result.CSVData || {};
            CSVData.ERROR = result.message;
            return CSVData;
        });

        var csvUtils = cmp.find('csvUtils');

        var csv = csvUtils.fromObjects(rows);
        csvUtils.download(csv, 'DataImportErrorDetails.csv');
    }
})