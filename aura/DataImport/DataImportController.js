({
    handleInit: function(cmp, event, helper){

        helper.execute(
            cmp,
            'vertic_SOQLProc',
            {
                'SOQL': 'SELECT Id, Label, DeveloperName, Flow_API_Name__c FROM Flow_Setting__mdt WHERE Type__c = \'Data Import\''
            },
            function (response) {
                var options = response.dto.records.map(function (record) {
                    return {
                        value: record.DeveloperName,
                        label: record.Label + ' (' + record.Flow_API_Name__c + ')'
                    }
                });
                cmp.set('v.meta.selectOptions.flowSettingOptions', options);
            }
        )
    }
})