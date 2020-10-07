@IsTest(SeeAllData=true)
private class vertic_FlowSettingProcTest {
    static testMethod void testBehavior() {
        vertic_Response response = new vertic_FlowSettingProc2().process(
            new vertic_Request('{"settingName":"Task_Flow","inputs":{"dto":{"payload":{"test":1,"activityDate":"2020-07-10"}}}}')
        );
        System.assertEquals(true, response.isValid);
    }
}