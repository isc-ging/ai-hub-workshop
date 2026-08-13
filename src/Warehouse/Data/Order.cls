Class Warehouse.Data.Order Extends %Persistent
{

Property Customer As Warehouse.Data.Customer [ Required ];

Property OrderDate As %Date [ Required ];

Property DeliveryAddress As %String(MAXLEN = 200) [ Required ];

Property Product As Warehouse.Data.Product [ Required ];

Property Quantity As %Integer [ Required ];

Index CustomerIndex On Customer;

Index OrderDateIndex On OrderDate;


Method %OnSave()
{
    set OrderDate = $HOROLOG

}



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
<Value>Product</Value>
</Value>
<Value name="6">
<Value>Quantity</Value>
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
