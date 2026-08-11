Class Warehouse.Data.OrderItem Extends %Persistent
{

Relationship Order As Warehouse.Data.Order [ Cardinality = parent, Inverse = Items ];

Property Product As Warehouse.Data.Product [ Required ];

Property Quantity As %Integer [ Required ];

Property UnitPrice As %Decimal(SCALE = 2) [ Required ];

Storage Default
{
<Data name="OrderItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Product</Value>
</Value>
<Value name="3">
<Value>Quantity</Value>
</Value>
<Value name="4">
<Value>UnitPrice</Value>
</Value>
</Data>
<DataLocation>^Warehouse.Data.Order.ItemsD</DataLocation>
<DefaultData>OrderItemDefaultData</DefaultData>
<IdLocation>^Warehouse.Data.Order.ItemsD</IdLocation>
<IndexLocation>^Warehouse.Data.Order.ItemsI</IndexLocation>
<StreamLocation>^Warehouse.Data.Order.ItemsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
