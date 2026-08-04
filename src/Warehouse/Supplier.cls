Class Warehouse.Supplier Extends %Persistent
{

Property Name As %String(MAXLEN = 100) [ Required ];

Property ContactEmail As %String(MAXLEN = 150);

Property Phone As %String(MAXLEN = 20);

Property LeadTimeDays As %Integer;

Index NameIndex On Name [ Unique ];

Storage Default
{
<Data name="SupplierDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>ContactEmail</Value>
</Value>
<Value name="4">
<Value>Phone</Value>
</Value>
<Value name="5">
<Value>LeadTimeDays</Value>
</Value>
</Data>
<DataLocation>^Warehouse.SupplierD</DataLocation>
<DefaultData>SupplierDefaultData</DefaultData>
<IdLocation>^Warehouse.SupplierD</IdLocation>
<IndexLocation>^Warehouse.SupplierI</IndexLocation>
<StreamLocation>^Warehouse.SupplierS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
