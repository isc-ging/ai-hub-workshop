Class Warehouse.AI.ConsoleAudit Extends %AI.Policy.Audit
{
/// Log execution to console
Method %LogExecution(call As %DynamicObject, metadata As %DynamicObject, result As %DynamicObject, duration As %Integer, status As %Status) As %Status
{

    Set argsStr = call.arguments

    Set resultStr = $System.Status.GetErrorText(status)
    If $$$ISOK(status), $IsObject(result) {
        Set resultJson = result.%Get("result_json", "")
        Set displayText = result.%Get("display_text", "")
        If (resultJson '= "") {
            Set resultStr = resultJson
        } ElseIf (displayText '= "") {
            Set resultStr = displayText
        } Else {
            Set resultStr = result.%ToJSON()
        }
    }

    Set esc = $Char(27)
    Set cCyan = esc_"[36m"
    Set cReset = esc_"[0m"

    Write !, cCyan, call.name, "(", argsStr, ") -> ", resultStr, " [", duration, "ms]", cReset, !
    Return $$$OK
}

}

