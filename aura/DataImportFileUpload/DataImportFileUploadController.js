({
    handleInit: function(cmp, event, helper){
        var hooks = {
            validate: function (cmp) {
                return new Promise(function (resolve, reject) {
                    var csvParsedData = cmp.get('v.meta.dto.csvParsedData');
                    if (!csvParsedData || !csvParsedData.data || !csvParsedData.data.length){
                        return reject(['No Data to Import']);
                    }
                    return resolve();
                });
            },
            onNext: function (cmp) {
                return new Promise($A.getCallback(function (resolve, reject) {

                    var csvParsedData = cmp.get('v.meta.dto.csvParsedData');

                    var checkOnly = cmp.get('v.meta.dto.checkOnly') === true;

                    cmp.set('v.meta.dto.importSummary', null);
                    cmp.set('v.isBusy', true);

                    cmp.set('v.meta.dto.progress.total', csvParsedData.data.length);
                    cmp.set('v.meta.dto.progress.current', 0);
                    cmp.set('v.meta.dto.progress.isVisible', true);
                    cmp.set('v.meta.dto.progress.startedOn', new Date());

                    helper.import(cmp, event, helper, csvParsedData, checkOnly).then(function (results) {
                        console.log('results', results);

                        var resultsWithCSVData = results.map(function (result, index) {
                            result.CSVData = csvParsedData.data[index] || {};
                            return result;
                        })

                        var failed = resultsWithCSVData.filter(function (result) {
                            return result.isValid !== true;
                        });

                        var summary = {
                            totalProcessed: results.length,
                            totalSucceeded: results.length - failed.length,
                            totalFailed: failed.length,
                            results: resultsWithCSVData
                        };

                        cmp.set('v.meta.dto.importSummary', summary);
                        return resolve();

                    }).catch(function (errors) {
                        console.log('errors', errors);
                        return resolve();
                    }).finally(function () {
                        cmp.set('v.isBusy', false);
                        cmp.set('v.meta.dto.progress.isVisible', false);
                    });

                }));
            }
        };

        cmp.set('v.hooks', hooks);
    },

    handleFilesChange: function(cmp, event, helper){

        var files = event.getSource().get('v.files');
        if(!files || !files.length){
            return;
        }

        cmp.set('v.meta.dto.csvParsedData', null);
        cmp.set('v.isBusy', true);

        helper.parseFile(cmp, files[0]).then(function (csvParsedData) {
            if(csvParsedData && csvParsedData.errors && csvParsedData.errors.length){
                csvParsedData.errors = csvParsedData.errors.sort(function(a, b){return a.row - b.row});
            }
            cmp.set('v.meta.dto.csvParsedData', csvParsedData);
        }).catch(function (error) {
            helper.utils(cmp).showToast({
                message: JSON.stringify(error),
                type: 'error'
            });
        }).finally(function () {
            cmp.set('v.isBusy', false);
        });

    },

    handleOnProgress: function(cmp, event, helper){

        var current = cmp.get('v.meta.dto.progress.current') || 0;
        current = current + 1;
        var total = cmp.get('v.meta.dto.progress.total');

        var value = (current * 100 / total).toFixed(2);

        cmp.set('v.meta.dto.progress.value', value);
        cmp.set('v.meta.dto.progress.current', current);
    }
})