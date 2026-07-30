Class Demo.Transactions Extends %Persistent
{

Property Product As Demo.Product [ Required ];

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
<DataLocation>^Demo.TransactionsD</DataLocation>
<DefaultData>TransactionsDefaultData</DefaultData>
<IdLocation>^Demo.TransactionsD</IdLocation>
<IndexLocation>^Demo.TransactionsI</IndexLocation>
<StreamLocation>^Demo.TransactionsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
