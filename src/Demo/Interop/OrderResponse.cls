Class Demo.Interop.OrderResponse Extends Ens.Response
{

Property StatusMessage As %String(MAXLEN = 500);

Property LeadTimeDays As %Integer;

Storage Default
{
<Data name="OrderResponseDefaultData">
<Subscript>"OrderResponse"</Subscript>
<Value name="1">
<Value>StatusMessage</Value>
</Value>
<Value name="2">
<Value>LeadTimeDays</Value>
</Value>
</Data>
<DefaultData>OrderResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
