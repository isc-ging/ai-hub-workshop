Class Warehouse.AI.ToolSet Extends %AI.ToolSet
{
    XData Definition [MimeType = "application/xml"] 
    {
        <ToolSet>
            <Policies>
                <Audit Class="Warehouse.AI.ConsoleAudit"/>
            </Policies>
        
            <Include Class="Warehouse.AI.LookupTools"/>
            <Include Class="Warehouse.AI.OrderTools"/>
        </ToolSet>
    }
}
