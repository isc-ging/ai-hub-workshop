Class Warehouse.Interop.Messages.ReviewRequest Extends Warehouse.Interop.Messages.MailMessage
{
    Property AgentNotes As %VarString;

    Property ReviewReason As %VarString; 

    Property Intent As %VarString;


Storage Default
{
<Data name="ReviewRequestDefaultData">
<Subscript>"ReviewRequest"</Subscript>
<Value name="1">
<Value>AgentNotes</Value>
</Value>
<Value name="2">
<Value>ReviewReason</Value>
</Value>
<Value name="3">
<Value>Intent</Value>
</Value>
</Data>
<DefaultData>ReviewRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
