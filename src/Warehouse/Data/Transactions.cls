Class Warehouse.Data.Transactions Extends %Persistent
{

Property Product As Warehouse.Data.Product [ Required ];

Property Date As %Date [ Required ];

Property Quantity As %Integer [ Required ];

Property Total As %Decimal(SCALE = 2) [ Required ];

Index ProductIndex On Product;

Index DateIndex On Date;

Storage Default
{
<Data name="TransactionsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Product</Value>
</Value>
<Value name="3">
<Value>Date</Value>
</Value>
<Value name="4">
<Value>Quantity</Value>
</Value>
<Value name="5">
<Value>Total</Value>
</Value>
</Data>
<DataLocation>^Warehouse.Data.TransactionsD</DataLocation>
<DefaultData>TransactionsDefaultData</DefaultData>
<IdLocation>^Warehouse.Data.TransactionsD</IdLocation>
<IndexLocation>^Warehouse.Data.TransactionsI</IndexLocation>
<StreamLocation>^Warehouse.Data.TransactionsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
