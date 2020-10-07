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

        try {

            Map<String, Object> requestMap;
            Map<String, Object> payloadMap;

            String flowSetting = this.request.params.get('flow');
            vertic_Utils.objects.throwIfBlank(flowSetting, '"flow" URL param is required!');
            String payloadJSON = this.request.getJSON();

            System.debug('payloadJSON: ' + payloadJSON);

            payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payloadJSON);

            requestMap = new Map<String, Object>{
                'settingName' => flowSetting,
                'inputs' => payloadMap
            };

            vertic_Response flowResponseVar = new vertic_FlowSettingProc().process(requestMap);
            if(flowResponseVar.isValid != true){
                throw new vertic_Structs.ProcessException(flowResponseVar.error.message);
            } else {
                this.response.dto.putAll(flowResponseVar.getMap());
            }

        } catch (Exception e) {
            this.response.dto.put('error', e.getMessage());
            this.response.isValid = false;
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