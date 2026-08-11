Class Warehouse.Interop.BO.ToEmailParsingAgent extends Ens.BusinessOperation
{

    XData MessageMap{
    <MapItems>
        <MapItem MessageType="Warehouse.Interop.Messages.MailMessage">
            <Method>CategoriseEmail</Method>
        </MapItem>
    </MapItems>
    }



    Method CategoriseEmail(pInput As Warehouse.Interop.Messages.MailMessage, 
                    output pOutput As Warehouse.Interop.Messages.MailMessage) As %Status
    {

        set agent = ##class(Warehouse.AI.Agents.EmailParser).%New()
        set status = agent.%Init() 
        if $$$ISERR(status){
            return status
        }

        set st = pInput.%JSONExportToString(.prompt)

        set session  = agent.CreateSession() 

        set response = agent.Chat(session, prompt)
        d session.%Save()
        set json = ##class(Warehouse.AI.BaseAgent).ExtractJSON(response.Content)

        try {
            set output = {}.%FromJSON(json)
        } catch ex {
            return $$$ERROR($$$GeneralError, "Agent returned malformed JSON: " _ response.Content)
        }

        if '$IsObject(output) || (output.category = "") {
            return $$$ERROR($$$GeneralError, "Agent response missing 'category' field: " _ response.Content)
        }

        set pOutput = pInput.%ConstructClone(pInput)
        set pOutput.Category = output.category
        return $$$OK

    }
}