({
    parseFile: function (cmp, file) {
        return new Promise($A.getCallback(function (resolve, reject) {

            cmp.find('papaParseCmp').parseCSV(
                file,
                {
                    header: true,
                    dynamicTyping: false,
                    skipEmptyLines: true,
                    complete: function(results) {
                        console.log(JSON.parse(JSON.stringify(results)));
                        return resolve(results);
                    },
                    error: function (error) {
                        return reject(error);
                    }
                }
            );

        }));
    },

    import: function(cmp, event, helper, csvParsedData, checkOnly){

        var promises = [];
        csvParsedData.data.forEach(function (csvRowData) {
            var importPromise = function () {
                return new Promise(function (resolve, reject) {
                    csvRowData.JSONData = JSON.stringify(csvRowData);
                    helper.utils(cmp).execute(
                        cmp,
                        'vertic_FlowSettingProc',
                        {
                            settingName: cmp.get('v.meta.dto.flowSetting'), //'Data_Import',
                            inputs: csvRowData,
                            checkOnly: checkOnly
                        },
                        function () {},
                        function () {}
                    ).then(resolve, function (errors) {
                        resolve({
                            isValid: false,
                            message: errors[0].message
                        });
                    }).finally(function () {
                        cmp.getConcreteComponent().getEvent('onProgress').fire();
                    });
                });
            }

            promises.push(importPromise);
        });

        return cmp.get('v.meta.dto.isParallel') == true ?
            Promise.all(promises.map(function (fn) { return fn(); })) :
            helper.sequencePromises(promises);
    },

    sequencePromises: function(promises){
        return new Promise(function (resolve, reject) {

            var results = [];

            promises.reduce(function (p, promise, index) {

                return p.then($A.getCallback(function (){
                    var isLast = index == promises.length - 1;
                    return promise().then(function (response) {
                        results.push(response);
                        if(isLast) {
                            resolve(results);
                        }
                    }).catch(function (reason) {
                        results.push({
                            isValid: false,
                            message: reason
                        });
                        if(isLast) {
                            resolve(results);
                        }
                    });
                }), reject);

            }, Promise.resolve());

        });
    },
})