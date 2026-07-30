Class Demo.Interop.OrderRequest Extends Ens.Request
{

Property ProductId As %Integer [ Required ];

Property Quantity As %Integer [ Required ];

Storage Default
{
<Data name="OrderRequestDefaultData">
<Subscript>"OrderRequest"</Subscript>
<Value name="1">
<Value>ProductId</Value>
</Value>
<Value name="2">
<Value>Quantity</Value>
</Value>
</Data>
<DefaultData>OrderRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
