Class Warehouse.Data.SupplierProduct Extends %Persistent
{

Property Supplier As Warehouse.Data.Supplier [ Required ];

Property Product As Warehouse.Data.Product [ Required ];

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
<DataLocation>^Warehouse.Data.SupplierProductD</DataLocation>
<DefaultData>SupplierProductDefaultData</DefaultData>
<IdLocation>^Warehouse.Data.SupplierProductD</IdLocation>
<IndexLocation>^Warehouse.Data.SupplierProductI</IndexLocation>
<StreamLocation>^Warehouse.Data.SupplierProductS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
