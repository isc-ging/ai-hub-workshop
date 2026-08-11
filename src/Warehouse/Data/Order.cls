Class Warehouse.Data.Order Extends %Persistent
{

Property Customer As Warehouse.Data.Customer [ Required ];

Property OrderDate As %Date [ Required ];

Property DeliveryAddress As %String(MAXLEN = 200) [ Required ];

Property Status As %String(VALUELIST = ",draft,confirmed") [ InitialExpression = "confirmed" ];

Relationship Items As Warehouse.Data.OrderItem [ Cardinality = children, Inverse = Order ];

Index CustomerIndex On Customer;

Index OrderDateIndex On OrderDate;

Storage Default
{
<Data name="OrderDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Customer</Value>
</Value>
<Value name="3">
<Value>OrderDate</Value>
</Value>
<Value name="4">
<Value>DeliveryAddress</Value>
</Value>
<Value name="5">
<Value>Status</Value>
</Value>
</Data>
<DataLocation>^Warehouse.Data.OrderD</DataLocation>
<DefaultData>OrderDefaultData</DefaultData>
<IdLocation>^Warehouse.Data.OrderD</IdLocation>
<IndexLocation>^Warehouse.Data.OrderI</IndexLocation>
<StreamLocation>^Warehouse.Data.OrderS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
