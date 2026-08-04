Class Warehouse.Product Extends %Persistent
{

Property SKU As %String(MAXLEN = 20) [ Required ];

Property Name As %String(MAXLEN = 100) [ Required ];

Property Category As %String(MAXLEN = 50);

Property Quantity As %Integer [ InitialExpression = 0 ];

Property UnitPrice As %Decimal(SCALE = 2);

Property ReorderLevel As %Integer [ InitialExpression = 10 ];

Property OnOrder As %Integer [ InitialExpression = 0 ];

Index SKUIndex On SKU [ Unique ];

Storage Default
{
<Data name="ProductDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SKU</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Category</Value>
</Value>
<Value name="5">
<Value>Quantity</Value>
</Value>
<Value name="6">
<Value>UnitPrice</Value>
</Value>
<Value name="7">
<Value>ReorderLevel</Value>
</Value>
<Value name="8">
<Value>OnOrder</Value>
</Value>
</Data>
<DataLocation>^Warehouse.ProductD</DataLocation>
<DefaultData>ProductDefaultData</DefaultData>
<IdLocation>^Warehouse.ProductD</IdLocation>
<IndexLocation>^Warehouse.ProductI</IndexLocation>
<StreamLocation>^Warehouse.ProductS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
