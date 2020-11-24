public without sharing class FlowPostProc extends vertic_AbstractProcessor {

    /**
     * ==============================================================================================================
     *                                              PROCESS
     * ==============================================================================================================
     */

    public override vertic_Response process(vertic_Request request) {
        this.request = (vertic_RestService.Request) request;
        this.response = (vertic_RestService.Response) super.response;

        this.doSubmit();

        return this.response;
    }


    /**
     * ==============================================================================================================
     *                                             PRIVATE METHODS
     * ==============================================================================================================
     */

    private void doSubmit() {

        String requestMapDump;
        try {

            String event = this.request.params.get('event');

            String flowSetting = vertic_Utils.objects.defaultIfNull(event, this.request.params.get('flow'));
            vertic_Utils.objects.throwIfBlank(flowSetting, '"flow" URL param is required!');
            String payloadJSON = this.request.getJSON();

            System.debug('payloadJSON: ' + payloadJSON);

            Map<String, Object> requestMap = new Map<String, Object>{
                'settingName' => flowSetting,
                'inputs' => (Map<String, Object>) JSON.deserializeUntyped(payloadJSON)
            };

            requestMapDump = JSON.serialize(requestMap);

            vertic_Response flowResponseVar = new vertic_FlowSettingProc().process(requestMap);
            if(flowResponseVar.isValid != true){
                throw new vertic_Structs.ProcessException(flowResponseVar.error.message);
            } else {
                this.response.dto.putAll(flowResponseVar.getMap());
            }

        } catch (Exception e) {
            this.response.error = new vertic_Structs.ErrorDetails(e.getMessage());
            this.response.isValid = false;

            Vertic_Async_Process__c asyncProcess = new Vertic_Async_Process__c(
                Autorun__c = false,
                Is_Queueable__c = false,
                Status__c = 'Failed',
                Processor__c = 'vertic_FlowSettingProc',
                Payload__c = requestMapDump,
                Details__c = e.getMessage()
            );
            insert asyncProcess;
        } finally {
            this.response.headers.put('Content-Type', 'application/json');
        }

    }


    /**
     * ==============================================================================================================
     *                                               STRUCTURES
     * ==============================================================================================================
     */

    private vertic_RestService.Response response;

    protected override vertic_Response getResponseInstance() {
        return new vertic_RestService.Response();
    }

    /** ============================================================================================================= */

    private vertic_RestService.Request request;

    public override Type getRequestType() {
        return vertic_RestService.Request.class;
    }

    public override vertic_Request getRequestInstance(String requestJSON) {
        return (vertic_RestService.Request) JSON.deserialize(requestJSON, this.getRequestType());
    }


}