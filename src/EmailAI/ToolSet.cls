Class EmailAI.ToolSet Extends %AI.ToolSet
{
    XData Definition [MimeType = "application/xml"]
    {
        <ToolSet>
            <Policies>
                <Audit Class="EmailAI.ConsoleAudit"/>
            </Policies>

            <Include Class="EmailAI.LookUpTools"/>
            <Include Class="EmailAI.OrderTools"/>
        </ToolSet>
    }
}
