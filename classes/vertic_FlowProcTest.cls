@isTest
public with sharing class vertic_FlowProcTest {

    @isTest
    private static void test() {
        Test.startTest();
        new vertic_FlowProc().process(new Map<String,Object>{
                'flow' => 'websiteIntegration',
                'inputs' => null,
                'outputFields' => new List<String>()
        });
        Test.stopTest();
    }
}