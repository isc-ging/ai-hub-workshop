Class Demo.StockMovement Extends %Persistent
{

Property Product As Demo.Product [ Required ];

Property Delta As %Integer [ Required ];

Property Reason As %String(MAXLEN = 200);

Property Timestamp As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3, 1)} ];

Property Reporter As %String;

Index ProductIndex On Product;

Index TimestampIndex On Timestamp;

Storage Default
{
<Data name="StockMovementDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Product</Value>
</Value>
<Value name="3">
<Value>Delta</Value>
</Value>
<Value name="4">
<Value>Reason</Value>
</Value>
<Value name="5">
<Value>Timestamp</Value>
</Value>
<Value name="6">
<Value>User</Value>
</Value>
<Value name="7">
<Value>Reporter</Value>
</Value>
</Data>
<DataLocation>^Demo.StockMovementD</DataLocation>
<DefaultData>StockMovementDefaultData</DefaultData>
<IdLocation>^Demo.StockMovementD</IdLocation>
<IndexLocation>^Demo.StockMovementI</IndexLocation>
<StreamLocation>^Demo.StockMovementS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
