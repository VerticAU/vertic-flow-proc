@IsTest
public class vertic_FlowSettingProcTest {
    @isTest
    private static void test() {
        Test.startTest();
        new vertic_FlowSettingProc().process(new Map<String,Object>{
            'inputs' => new Map<String, String>{
                'test' => 'test'
            },
            'setting' => new vertic_AutoMapper().getSObjectAsMap(new Flow_Setting__mdt(
                DeveloperName = 'test',
                Flow_API_Name__c = 'websiteIntegration',
                Input__c = '{ "inputPayload" : "dto.test", "inputActivityDate" : { "trueValues" : null, "format" : "yyyy-MM-dd", "type" : "Date", "disregardBlankValue" : true, "trimValue" : true, "path" : "dto.donation.date" } }'
            ))
        });
        Test.stopTest();
    }
}