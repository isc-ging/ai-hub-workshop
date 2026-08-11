Class Warehouse.Interop.Messages.MailMessage Extends (Ens.MessageBody, %JSON.Adaptor)
{

Property Subject As %String(MAXLEN = 1000);

Property MailFrom As %String(MAXLEN = 1000);

Property MailTo As list Of %String(MAXLEN = 8000);

Property Cc As list Of %String(MAXLEN = 8000);

Property Bcc As list Of %String(MAXLEN = 8000);

Property ReplyTo As %String(MAXLEN = 1000);

Property MailDate As %String;

Property TextData As %Stream.GlobalCharacter;

Property HTMLData As %Stream.GlobalCharacter;

Property Category As %String(VALUELIST=",Order,Support,Other") [InitialExpression=""];

/// Populate this message from a raw %Net.MailMessage received by the inbound adapter.
ClassMethod FromNetMail(pMail As %Net.MailMessage, Output pMsg As Warehouse.Interop.Messages.MailMessage) As %Status
{
    Set pMsg = ##class(Warehouse.Interop.Messages.MailMessage).%New()
    Set pMsg.Subject  = pMail.Subject
    Set pMsg.MailFrom = pMail.From
    Set pMsg.ReplyTo  = pMail.ReplyTo
    Set pMsg.MailDate = pMail.Date

    Do pMsg.MailTo.Clear()
    For i = 1:1:pMail.To.Count() {
        Do pMsg.MailTo.Insert(pMail.To.GetAt(i))
    }

    Do pMsg.Cc.Clear()
    For i = 1:1:pMail.Cc.Count() {
        Do pMsg.Cc.Insert(pMail.Cc.GetAt(i))
    }

    Do pMsg.Bcc.Clear()
    For i = 1:1:pMail.Bcc.Count() {
        Do pMsg.Bcc.Insert(pMail.Bcc.GetAt(i))
    }

    If pMail.IsHTML {
        Set pMsg.HTMLData = ##class(%Stream.GlobalCharacter).%New()
        Set sc = pMsg.HTMLData.CopyFrom(pMail.HTMLData)
        Return:$$$ISERR(sc) sc
    } Else {
        Set pMsg.TextData = ##class(%Stream.GlobalCharacter).%New()
        Set sc = pMsg.TextData.CopyFrom(pMail.TextData)
        Return:$$$ISERR(sc) sc
    }

    Return $$$OK
}
Storage Default
{
<Data name="MailMessageDefaultData">
<Subscript>"MailMessage"</Subscript>
<Value name="1">
<Value>Subject</Value>
</Value>
<Value name="2">
<Value>MailFrom</Value>
</Value>
<Value name="3">
<Value>MailTo</Value>
</Value>
<Value name="4">
<Value>Cc</Value>
</Value>
<Value name="5">
<Value>Bcc</Value>
</Value>
<Value name="6">
<Value>ReplyTo</Value>
</Value>
<Value name="7">
<Value>MailDate</Value>
</Value>
<Value name="8">
<Value>TextData</Value>
</Value>
<Value name="9">
<Value>HTMLData</Value>
</Value>
<Value name="10">
<Value>Category</Value>
</Value>
</Data>
<DefaultData>MailMessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}