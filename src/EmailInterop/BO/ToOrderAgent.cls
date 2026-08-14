Class EmailInterop.BO.ToOrderAgent extends Ens.BusinessOperation
{
    Property HumanReviewTarget As Ens.DataType.ConfigName;

    PARAMETER SETTINGS = "HumanReviewTarget:Basic";

    XData MessageMap
    {
    <MapItems>
        <MapItem MessageType="EmailInterop.Messages.MailMessage">
            <Method>OnMessage</Method>
        </MapItem>
    </MapItems>
    }

    Method OnMessage(pInput As EmailInterop.Messages.MailMessage, Output pOut As Ens.Response) As %Status
    {
        set agent = ##class(EmailAI.Agent).%New()
        set sc = agent.%Init()

        if $$$ISERR(sc) {
            quit sc
        }

        set session = agent.CreateSession()

        set st  = pInput.%JSONExportToString(.prompt)

        set response = agent.Chat(session, prompt)
        d session.%Save()
        set json = ##class(Utils.JSON).ExtractJSON(response.Content)

        try {
            set output = {}.%FromJSON(json)
        } catch ex {
            return $$$ERROR($$$GeneralError, "OrderAgent returned malformed JSON: " _ response.Content)
        }

        if '$IsObject(output) {
            return $$$ERROR($$$GeneralError, "OrderAgent response is not a JSON object: " _ response.Content)
        }

        if output.ReviewRequired {
            set reviewRequest = ##class(EmailInterop.Messages.ReviewRequest).%New()
            set reviewRequest.Subject  = pInput.Subject
            set reviewRequest.MailFrom = pInput.MailFrom
            set reviewRequest.ReplyTo  = pInput.ReplyTo
            set reviewRequest.MailDate = pInput.MailDate
            set reviewRequest.Category = pInput.Category
            set reviewRequest.TextData = pInput.TextData
            set reviewRequest.HTMLData = pInput.HTMLData

            for i = 1:1:pInput.MailTo.Count() {
                do reviewRequest.MailTo.Insert(pInput.MailTo.GetAt(i))
            }
            for i = 1:1:pInput.Cc.Count() {
                do reviewRequest.Cc.Insert(pInput.Cc.GetAt(i))
            }
            for i = 1:1:pInput.Bcc.Count() {
                do reviewRequest.Bcc.Insert(pInput.Bcc.GetAt(i))
            }

            set reviewRequest.AgentNotes   = output.AgentNotes
            set reviewRequest.ReviewReason = output.ReasonForReview


            return ..SendRequestAsync(..HumanReviewTarget, reviewRequest)
        }

        return $$$OK
    }

Storage Default
{
<Data name="ToOrderAgentDefaultData">
<Subscript>"ToOrderAgent"</Subscript>
<Value name="1">
<Value>HumanReviewTarget</Value>
</Value>
</Data>
<DefaultData>ToOrderAgentDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
