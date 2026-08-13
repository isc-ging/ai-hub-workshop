Class Warehouse.AI.Agent Extends %AI.Agent
{

    /// LLM Model
    Parameter MODELCONFIG = "bedrock.claude-haiku-4-5";

    Parameter TOOLSETS = "Warehouse.AI.ToolSet";

    /// Initialization method. Can be used to set provider, or add stateful tools and policies. 
    /// Called by `.%Init()`
    Method %OnInit() As %Status{
        
        set sc = $$$OK
        w "Initialising"
        try {
        
        set sc = ##class(%ConfigStore.Configuration).GetDetails("AI.LLM."_..#MODELCONFIG, .details, 0, 1)
        quit:$$$ISERR(sc) 

        set ..Provider = ##class(%AI.Provider).Create(details."model_provider", details)

        set ..Model = details.model

        } catch (ex) {
        set sc = ex.AsStatus()
    }
    quit sc
    }
    


    XData INSTRUCTIONS [MimeType="text/markdown"] { 
            # Procurement Agent

            You process procurement requests received from customers.

            ## Responsibilities

            - Determine the customer's intent.
            - Extract customer, product, quantity, delivery and order information.
            - Return the result using the supplied response structure.
            - Report information that is required but unavailable.

            ## Restrictions

            - Do not invent customer IDs, product IDs, prices or order references.
            - Do not claim that an order has been created.
            - Preserve uncertainty when the email is ambiguous.

            Expected result extract: 
            ```
            {
                "intent": "place_order",
                "status": "information_required",
                "customerName": "Northwind",
                "items": [
                    {
                    "productId": "TS-400",
                    "quantity": 20
                    }
                ],
                "missingInformation": [
                    "Delivery address must be resolved"
                ],
                "actionsTaken": []
            }
            ```

            Your response must begin with { and end with }, and only include correctly formatted JSON data. DO NOT WRAP YOUR RESPONSE IN CODE FENCES.

    }

    ClassMethod ProcessEmail(pEmail as %String) As %DynamicObject
    {
    // Create an initialise agent
    set agent = ##class(Warehouse.AI.Agent).%New()
    set sc = agent.%Init()

    if $$$ISERR(sc){ quit sc} // Error handling

    set session = agent.CreateSession()

    set response = agent.Chat(session, pEmail)

    do session.%Save() // Save session to DB (Can access later)

    set responseObj = ##class(Warehouse.Utils.JSON).ExtractJSON(response.Content)

    return responseObj

}

}
