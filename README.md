# vertic-flow-proc

Migration Script

```apex
List<Flow_Setting__mdt> flowSettings = [SELECT Id, Label, DeveloperName, (SELECT Id, Flow_Input_Name__c, Flow_Input_Format__c, Source_Path__c, Trim_Value__c, Default__c, Disregard_Blank_Value__c, Flow_Variable_Type__c FROM Flow_Mappings__r) FROM Flow_Setting__mdt];

Map<Id, Flow_Input_Format__mdt> flowInputFormatMap = new Map<Id, Flow_Input_Format__mdt>([SELECT Id, Type__c, Format__c, True_Values__c FROM Flow_Input_Format__mdt]);


for (Flow_Setting__mdt flowSettingVar : flowSettings) {
    vertic_DTO flowSettingDTO = new vertic_DTO();
    List<String> outputVars = new List<String>();
    for (Flow_Mapping__mdt flowMappingVar : flowSettingVar.Flow_Mappings__r) {
        
        if('Output'.equalsIgnoreCase(flowMappingVar.Flow_Variable_Type__c)){
            outputVars.add(flowMappingVar.Flow_Input_Name__c);
        } else {
            vertic_DTO formatDTO = new vertic_DTO();
            formatDTO.put('path', flowMappingVar.Source_Path__c);
            if(flowMappingVar.Default__c != null){
                formatDTO.put('default', flowMappingVar.Default__c);
            }
            formatDTO.put('trimValue', flowMappingVar.Trim_Value__c);
            formatDTO.put('disregardBlankValue', flowMappingVar.Disregard_Blank_Value__c);

            Flow_Input_Format__mdt formatVar = flowInputFormatMap.get(flowMappingVar.Flow_Input_Format__c);
            if(formatVar != null){
                formatDTO.put('type', formatVar.Type__c);
                formatDTO.put('format', formatVar.Format__c);
                formatDTO.put('trueValues', formatVar.True_Values__c);
            }
            
            if(flowMappingVar.Flow_Input_Format__c == null && flowMappingVar.Trim_Value__c == true && flowMappingVar.Disregard_Blank_Value__c == true && flowMappingVar.Default__c == null){
                flowSettingDTO.put(flowMappingVar.Flow_Input_Name__c, flowMappingVar.Source_Path__c);
            } else {
                flowSettingDTO.put(flowMappingVar.Flow_Input_Name__c, formatDTO.getMap());
            }
        }
    }
    System.debug(flowSettingDTO);
    vertic_SettingService.setMetadataTypeAsync(
        Flow_Setting__mdt.SObjectType,
        flowSettingVar.DeveloperName,
        flowSettingVar.Label,
        new Map<String, Object>{
            'Input__c' => JSON.serializePretty(flowSettingDTO.getMap()),
            'Output__c' => String.join(outputVars, ',')
        }
    );
}
```
