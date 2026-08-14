Class Warehouse.Order Extends %Persistent
{

Property Customer As Warehouse.Customer [ Required ];

Property OrderDate As %TimeStamp [ Required ];

Property DeliveryAddress As %String(MAXLEN = 200) [ Required ];

Property Product As Warehouse.Product [ Required ];

Property Quantity As %Integer [ Required ];

Index CustomerIndex On Customer;

Index OrderDateIndex On OrderDate;


Method %OnAddToSaveSet(
    depth As %Integer,
    insert As %Integer,
    callcount As %Integer) As %Status
{
    If insert {
        Set ..OrderDate = $ZDT($H,3)
    }
    Quit $$$OK

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
<DataLocation>^Warehouse.OrderD</DataLocation>
<DefaultData>OrderDefaultData</DefaultData>
<IdLocation>^Warehouse.OrderD</IdLocation>
<IndexLocation>^Warehouse.OrderI</IndexLocation>
<StreamLocation>^Warehouse.OrderS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
