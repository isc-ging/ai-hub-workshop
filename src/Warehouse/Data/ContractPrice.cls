Class Warehouse.Data.ContractPrice Extends %Persistent
{

Property Customer As Warehouse.Data.Customer [ Required ];

Property Product As Warehouse.Data.Product [ Required ];

Property UnitPrice As %Decimal(SCALE = 2) [ Required ];

Index CustomerProductIndex On (Customer, Product) [ Unique ];

Storage Default
{
<Data name="ContractPriceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Customer</Value>
</Value>
<Value name="3">
<Value>Product</Value>
</Value>
<Value name="4">
<Value>UnitPrice</Value>
</Value>
</Data>
<DataLocation>^Warehouse.Data.ContractPriceD</DataLocation>
<DefaultData>ContractPriceDefaultData</DefaultData>
<IdLocation>^Warehouse.Data.ContractPriceD</IdLocation>
<IndexLocation>^Warehouse.Data.ContractPriceI</IndexLocation>
<StreamLocation>^Warehouse.Data.ContractPriceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
