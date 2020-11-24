@isTest
public with sharing class FlowPostProcTest {

    @isTest
    static void test() {

        vertic_RestService.Request request = new vertic_RestService.Request();

        request.params.put('event', 'Logout Event');
        request.params.put('flow','Create Lead');


        String jSonString = JSON.serialize(new Map<String, Object>{});

        System.assertNotEquals(null, new FlowPostProc().getRequestInstance(jSonString));
        System.assertNotEquals(null, new FlowPostProc().process(request));

    }
}