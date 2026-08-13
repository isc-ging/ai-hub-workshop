Class Warehouse.Data.DraftOrder Extends Warehouse.Data.Order
{

Property ReviewRequired As %Boolean [ InitialExpression = 0 ];
Storage Default
{
<Data name="DraftOrderDefaultData">
<Subscript>"DraftOrder"</Subscript>
<Value name="1">
<Value>ReviewRequired</Value>
</Value>
</Data>
<DefaultData>DraftOrderDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
