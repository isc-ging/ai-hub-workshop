Class Demo.SupplierProduct Extends %Persistent
{

Property Supplier As Demo.Supplier [ Required ];

Property Product As Demo.Product [ Required ];

Property LastOrderDate As %Date;

Property IsPreferred As %Boolean [ InitialExpression = 0 ];

Index SupplierIndex On Supplier;

Index ProductIndex On Product;

Storage Default
{
<Data name="SupplierProductDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Supplier</Value>
</Value>
<Value name="3">
<Value>Product</Value>
</Value>
<Value name="4">
<Value>LastOrderDate</Value>
</Value>
<Value name="5">
<Value>IsPreferred</Value>
</Value>
</Data>
<DataLocation>^Demo.SupplierProductD</DataLocation>
<DefaultData>SupplierProductDefaultData</DefaultData>
<IdLocation>^Demo.SupplierProductD</IdLocation>
<IndexLocation>^Demo.SupplierProductI</IndexLocation>
<StreamLocation>^Demo.SupplierProductS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
