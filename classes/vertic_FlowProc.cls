public virtual class vertic_FlowProc extends vertic_AbstractProcessor implements vertic_Structs.IRollbackable {

    /**
     * ==============================================================================================================
     *                                              PROCESS
     * ==============================================================================================================
     */

    public virtual override vertic_Response process(vertic_Request request) {
        this.request = request;

        this.callFlow();

        return this.response;
    }


    /**
     * ==============================================================================================================
     *                                             PRIVATE METHODS
     * ==============================================================================================================
     */

    private String flowName;
    private Map<String, Object> inputs;
    private List<String> outputFields;

    private void callFlow() {

        this.flowName = this.request.getRequiredString('flow');
        this.inputs = (Map<String, Object>) this.request.get('inputs');
        this.outputFields = this.request.getListAsStrings('outputFields');
        
        if(this.inputs == null){
            this.inputs = new Map<String, Object>();
        }

        Flow.Interview flowToExecute = Flow.Interview.createInterview(this.flowName, this.inputs);
        flowToExecute.start();

        String flowFaultMessage = (String) flowToExecute.getVariableValue('FlowFaultMessage');
        if(String.isNotBlank(flowFaultMessage)){
            throw new vertic_Structs.ProcessException(flowFaultMessage);
        }

        if (outputFields != null && !outputFields.isEmpty()) {
            for (String outputField : outputFields) {
                this.response.put(outputField, flowToExecute.getVariableValue(outputField));
            }
        }

    }


    /**
     * ==============================================================================================================
     *                                               STRUCTURES
     * ==============================================================================================================
     */

    // Proposed Live Templates to override Super properties:
    // vertic_request
    // vertic_response


}