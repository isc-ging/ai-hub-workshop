Class Warehouse.AI.ToolSet Extends %RegisteredObject
{
    XData DEFINITION {
        <ToolSet>
            <Description>Sample Toolset</Description>
            <Policies>
                <Audit Class="Warehouse.AI.ConsoleAudit"/>
            </Policies>
        
            <Include Class="Warehouse.AI.LookupTools.cls"/>
        </ToolSet>
    }
}
