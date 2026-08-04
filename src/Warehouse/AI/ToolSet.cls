Class Warehouse.AI.ToolSet extends %AI.ToolSet [DependsOn =Warehouse.AI.Tools]
{
    /// XML Definition
    XData Definition [ MimeType = application/xml ]
    {
        <ToolSet Name = "Warehouse Manager Toolset">
            <Description>
                Warehouse management tools combined with Console policies. 
            </Description>

            <!-- Add policies to the tools in use  -->
            <Policies>

                <!-- Prompt user for approval in console for each tool call -->
                <Authorization Class="%AI.Policy.ConsoleAuth"/> 
                
                <!-- Print tool call in console -->
                <Audit Class="%AI.Policy.ConsoleAudit"/> 
            
            <!-- IMPORTANT, Console policies will not work over MCP and may cause errors  -->
            </Policies>

            <!-- Include our tool calls --> 
            <Include Class="Warehouse.AI.Tools"/>

            <!-- Could also add in-line tools/queries, external MCP servers, tool filters etc -->
        </ToolSet>
    }

}   
