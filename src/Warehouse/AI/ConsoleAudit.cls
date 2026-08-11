Class Warehouse.AI.ConsoleAudit Extends %AI.Policy.Audit
{
/// Log execution to console
Method %LogExecution(call As %DynamicObject, metadata As %DynamicObject, result As %DynamicObject, duration As %Integer, status As %Status) As %Status
{
    Try {
        Set argsStr = call.arguments.%ToJSON()

        Set resultStr = $System.Status.GetErrorText(status)
        If $$$ISOK(status) {
            Set resultStr = result.%ToJSON()
        }

        Write !, call.name, "(", argsStr, ") -> ", resultStr, " [", duration, "ms]", !
    } Catch {}
    Return $$$OK
}

}

