Class Warehouse.Data.Customer Extends %Persistent
{

Property CustomerId As %String(MAXLEN = 20) [ Required ];

Property Organisation As %String(MAXLEN = 150) [ Required ];

Property ContactEmail As %String(MAXLEN = 150) [ Required ];

Property Status As %String(VALUELIST = ",active,inactive") [ InitialExpression = "active" ];

Property Trusted As %Boolean [ InitialExpression = 0 ];

Property DefaultDeliveryAddress As %String(MAXLEN = 200);

Index OrganisationIndex On Organisation [ Unique ];

Index CustomerIdIndex On CustomerId [ Unique ];

Index ContactEmailIndex On ContactEmail [ Unique ];

Storage Default
{
<Data name="CustomerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Organisation</Value>
</Value>
<Value name="3">
<Value>ContactEmail</Value>
</Value>
<Value name="4">
<Value>Trusted</Value>
</Value>
<Value name="5">
<Value>CustomerId</Value>
</Value>
<Value name="6">
<Value>Status</Value>
</Value>
<Value name="7">
<Value>DefaultDeliveryAddress</Value>
</Value>
</Data>
<DataLocation>^Warehouse.Data.CustomerD</DataLocation>
<DefaultData>CustomerDefaultData</DefaultData>
<IdLocation>^Warehouse.Data.CustomerD</IdLocation>
<IndexLocation>^Warehouse.Data.CustomerI</IndexLocation>
<StreamLocation>^Warehouse.Data.CustomerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
