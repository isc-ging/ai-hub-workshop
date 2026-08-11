Class Warehouse.Customer Extends %Persistent
{

Property Organisation As %String(MAXLEN = 150) [ Required ];

Property ContactEmail As %String(MAXLEN = 150) [ Required ];

Property Trusted As %Boolean [ InitialExpression = 0 ];

Index OrganisationIndex On Organisation [ Unique ];

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
</Data>
<DataLocation>^Warehouse.CustomerD</DataLocation>
<DefaultData>CustomerDefaultData</DefaultData>
<IdLocation>^Warehouse.CustomerD</IdLocation>
<IndexLocation>^Warehouse.CustomerI</IndexLocation>
<StreamLocation>^Warehouse.CustomerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
