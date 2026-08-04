Class Warehouse.Transactions Extends %Persistent
{

Property Product As Warehouse.Product [ Required ];

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
<DataLocation>^Warehouse.TransactionsD</DataLocation>
<DefaultData>TransactionsDefaultData</DefaultData>
<IdLocation>^Warehouse.TransactionsD</IdLocation>
<IndexLocation>^Warehouse.TransactionsI</IndexLocation>
<StreamLocation>^Warehouse.TransactionsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
