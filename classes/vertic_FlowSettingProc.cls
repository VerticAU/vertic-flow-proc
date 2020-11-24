public class vertic_FlowSettingProc extends vertic_FlowProc {

    /**
     * ==============================================================================================================
     *                                              PROCESS
     * ==============================================================================================================
     */

    public override vertic_Response process(vertic_Request request) {
        this.request = request;

        this.doSubmit();

        return this.response;
    }


    /**
     * ==============================================================================================================
     *                                             PRIVATE METHODS
     * ==============================================================================================================
     */

    private Flow_Setting__mdt flowSetting;

    private void doSubmit() {

        if(this.request.has('setting')){
            this.flowSetting = new Flow_Setting__mdt();
            this.request.getMapper().mapToSObject('setting', this.flowSetting);
        } else {
            this.retrieveFlowSetting();
        }

        this.mapInputs();
        this.mapOutputs();

        this.request.put('flow', this.flowSetting.Flow_API_Name__c);

        Boolean isCheckOnly = this.request.getBoolean('checkOnly') == true;
        Savepoint checkOnlySavepoint = isCheckOnly ? Database.setSavepoint() : null;

        try {
            super.process(request);
        } catch (Exception ex) {
            throw ex;
        } finally {
            if (checkOnlySavepoint != null){
                Database.rollback(checkOnlySavepoint);
            }
        }

    }

    private void retrieveFlowSetting() {

        String flowSettingId = this.request.getString('settingId');
        String flowSettingName = this.request.getString('settingName');

        fflib_QueryFactory queryFactory = new fflib_QueryFactory(Flow_Setting__mdt.SObjectType);
        queryFactory.selectFields(new Set<SObjectField>{
            Flow_Setting__mdt.Flow_API_Name__c,
            Flow_Setting__mdt.Input__c,
            Flow_Setting__mdt.Output__c
        });

        if (String.isNotBlank(flowSettingId)) {
            queryFactory.setCondition('Id = :flowSettingId');
            this.flowSetting = (Flow_Setting__mdt) vertic_Utils.arrays.firstOrException(
                Database.query(queryFactory.toSOQL()),
                'Flow Setting with Id ' + flowSettingId + ' not found.'
            );
        } else if (String.isNotBlank(flowSettingName)) {
            queryFactory.setCondition('DeveloperName = :flowSettingName');
            this.flowSetting = (Flow_Setting__mdt) vertic_Utils.arrays.firstOrException(
                Database.query(queryFactory.toSOQL()),
                'Flow Setting with API Name ' + flowSettingName + ' not found.'
            );
        } else {
            throw new vertic_Structs.MissingDataException('Flow Setting parameters are missing. Please use the "settingId", "settingName" or "setting" to init a Flow Setting for processing.');
        }

    }

    private void mapInputs(){
        Map<String, Object> inputsMap = (Map<String, Object>) this.request.get('inputs');
        Map<String, Object> flowSettingInputMap = (Map<String, Object>) JSON.deserializeUntyped(this.flowSetting.Input__c);

        Map<String, Object> mappedInputs = mapFlowInputs(inputsMap, flowSettingInputMap);

        this.request.put('inputs', mappedInputs);
    }

    private void mapOutputs(){
        String outputStr = this.flowSetting.Output__c;
        List<String> outputVariables = new List<String>();
        if(String.isNotBlank(outputStr)){
            outputVariables.addAll(outputStr.split(','));
        }

        this.request.put('outputFields', outputVariables);
    }

    @TestVisible
    //{a: 1, b:2}
    //{a: inoutAVar, b: inputVarB}
    //{inoutAVar: 1, inputVarB: 2}
    private static Map<String, Object> mapFlowInputs(Map<String, Object> inputsMap, Map<String, Object> flowSettingInputMap){

        vertic_DTO inputDTO = new vertic_DTO(inputsMap);
        Map<String, Object> mappedInputsMap = new Map<String, Object>();

        for (String inputVarName : flowSettingInputMap.keySet()) {
            String inputName = inputVarName;

            String valuePath;

            Object inputSetting = flowSettingInputMap.get(inputVarName);
            vertic_DTO inputSettingDTO;
            if(inputSetting instanceof String){
                valuePath = (String)inputSetting;
                inputSettingDTO = new vertic_DTO();
            } else {
                inputSettingDTO = new vertic_DTO((Map<String, Object>) inputSetting);
                valuePath = inputSettingDTO.getRequiredString('path');
            }

            final Object inputDefault = inputSettingDTO.getString('default');
            final Boolean isTrimValue = inputSettingDTO.has('trimValue') != true ? true : inputSettingDTO.getBoolean('trimValue') == true;
            final Boolean disregardBlankValue = inputSettingDTO.has('disregardBlankValue') != true ? true : inputSettingDTO.getBoolean('disregardBlankValue') == true;
            
            final String inputType = inputSettingDTO.getString('type');

            System.debug('valuePath: ' + valuePath);

            Object value = inputDTO.get(valuePath);
            //inputsMap.remove(columnName);

            if(vertic_Utils.objects.isBlankValue(value) && inputDefault != null){
                value = inputDefault;
            }

            if(value instanceof String && value != null && isTrimValue == true){
                value = ((String)value).trim();
            }

            if(disregardBlankValue == true && vertic_Utils.objects.isBlankValue(value)){
                continue;
            }

            if (String.isNotBlank(inputType)) {

                if ('Date'.equalsIgnoreCase(inputType)) {
                    String valueStr = value instanceof String ? (String) value : null;
                    String dateFormat = inputSettingDTO.getString('format');
                    if(String.isBlank(dateFormat) || 'ISO'.equalsIgnoreCase(dateFormat)){
                        dateFormat = 'yyyy-MM-dd';
                    }
                    Date dateVar = String.isBlank(valueStr) ? null :
                        String.isBlank(dateFormat) ?
                            vertic_Utils.dates.parseDateAusFormat(valueStr) :
                            vertic_Utils.dates.parseDateAnyFormat(valueStr, dateFormat);

                    value = dateVar == null ? null : vertic_Utils.dates.dateToDateTime(dateVar).format('YYYY-MM-dd');
                } else if ('Datetime'.equalsIgnoreCase(inputType)) {
                    String valueStr = value instanceof String ? (String) value : null;
                    String dateFormat = inputSettingDTO.getString('format');
                    if(String.isBlank(dateFormat) || 'ISO'.equalsIgnoreCase(dateFormat)){
                        dateFormat = 'yyyy-MM-dd';
                    }
                    DateTime dateTimeVar = String.isBlank(valueStr) ? null :
                        String.isBlank(dateFormat) ?
                            vertic_Utils.dates.parseDatetimeAusFormat(valueStr) :
                            vertic_Utils.dates.parseDatetimeAnyFormat(valueStr, dateFormat);

                    value = dateTimeVar == null ? null : dateTimeVar.format('YYYY-MM-dd');
                } else if ('Boolean'.equalsIgnoreCase(inputType)){

                    String valueStr = value instanceof String ? (String) value : null;

                    if(valueStr != null){
                        String trueValuesStr = vertic_Utils.objects.defaultIfNull(inputSettingDTO.getString('trueValues'), 'true,yes,1');
                        List<String> trueValues = trueValuesStr.split(',');
                        Set<String> trueValuesFormatted = new Set<String>();
                        for (String val : trueValues) {
                            trueValuesFormatted.add(val.trim().toUpperCase());
                        }
                        value = String.isBlank(valueStr) ? false : trueValuesFormatted.contains(valueStr.trim().toUpperCase());
                    } else if (!(value instanceof Boolean)){
                        value = false;
                    }
                }
            }

            mappedInputsMap.put(inputName, value);
        }
        return mappedInputsMap;
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