Class Warehouse.Interop.BO.ToHumanReview Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.EMail.OutboundAdapter";

/// Department mailbox for order-review requests flagged as out of stock.
Property StockReviewEmail As %String(MAXLEN = 200) [ InitialExpression = "stock-review@warehouse.local" ];

/// Department mailbox for order-review requests flagged for customer trust/credit reasons.
Property CreditReviewEmail As %String(MAXLEN = 200) [ InitialExpression = "credit-review@warehouse.local" ];

/// Fallback department mailbox for any other review reason, or for messages with no specific intent (e.g. Category=Other).
Property GeneralReviewEmail As %String(MAXLEN = 200) [ InitialExpression = "review@warehouse.local" ];

Parameter SETTINGS = "StockReviewEmail:Basic,CreditReviewEmail:Basic,GeneralReviewEmail:Basic";

XData MessageMap
{
<MapItems>
        <MapItem MessageType="Warehouse.Interop.Messages.ReviewRequest">
            <Method>OnReviewRequest</Method>
        </MapItem>
        <MapItem MessageType="Warehouse.Interop.Messages.MailMessage">
            <Method>OnMailMessage</Method>
        </MapItem>
    </MapItems>
}

Method OnReviewRequest(pInput As Warehouse.Interop.Messages.ReviewRequest, Output pOut As Ens.Response) As %Status
{
        $$$LOGINFO("Human review required for message from " _ pInput.MailFrom _ " — reason: " _ pInput.ReviewReason)

        set toAddress = ..GetDepartmentEmail(pInput.Intent)

        set body = "Review reason: " _ pInput.ReviewReason _ $char(10)
        _ "Intent: " _ pInput.Intent _ $char(10)
        _ "Agent notes: " _ pInput.AgentNotes _ $char(10, 10)
        _ ..FormatOriginalMessage(pInput)

        return ..SendReviewEmail(toAddress, "[Review Required] " _ pInput.Subject, body)
}

Method OnMailMessage(pInput As Warehouse.Interop.Messages.MailMessage, Output pOut As Ens.Response) As %Status
{
        $$$LOGINFO("Human review required for message from " _ pInput.MailFrom _ " — category: " _ pInput.Category)

        set toAddress = ..GeneralReviewEmail

        set body = "Category: " _ pInput.Category _ $char(10, 10)
        _ ..FormatOriginalMessage(pInput)

        return ..SendReviewEmail(toAddress, "[Review Required] " _ pInput.Subject, body)
}

/// Map a ReviewRequest.Intent value (currently mirrors OrderAgent's ReasonForReview: OutOfStock, UntrustedCustomer, NewCustomer, Other) to a department mailbox.
Method GetDepartmentEmail(pIntent As %String) As %String
{
        quit $CASE(pIntent,
            "OutOfStock": ..StockReviewEmail,
            "UntrustedCustomer": ..CreditReviewEmail,
            "NewCustomer": ..CreditReviewEmail,
            : ..GeneralReviewEmail)
}

Method FormatOriginalMessage(pInput As Warehouse.Interop.Messages.MailMessage) As %String
{
        set body = ""
        if $IsObject(pInput.TextData) && (pInput.TextData.Size > 0) {
            set body = pInput.TextData.Read($$$MaxStringLength)
        } elseif $IsObject(pInput.HTMLData) && (pInput.HTMLData.Size > 0) {
            set body = pInput.HTMLData.Read($$$MaxStringLength)
        }

        quit "Original message from: " _ pInput.MailFrom _ $char(10)
        _ "Subject: " _ pInput.Subject _ $char(10)
        _ "Date: " _ pInput.MailDate _ $char(10, 10)
        _ body
}

Method SendReviewEmail(pToAddress As %String, pSubject As %String, pBody As %String) As %Status
{
        set mailMsg = ##class(%Net.MailMessage).%New()
        do mailMsg.To.Insert(pToAddress)
        set mailMsg.Subject = pSubject

        set mailMsg.TextData = ##class(%Stream.GlobalCharacter).%New()
        do mailMsg.TextData.Write(pBody)

        return ..Adapter.SendMail(mailMsg, .tFailedRecipients)
}

}
