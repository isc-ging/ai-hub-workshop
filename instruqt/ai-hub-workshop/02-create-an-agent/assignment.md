---
slug: create-an-agent
id: mielhz28oe7q
type: challenge
title: Creating an Agent
difficulty: ""
enhanced_loading: null
---


Let's start by creating our basic agent. Open the [VS Code](tab-0) tab, then open the file `src/Warehouse/AI/Agent.cls`

To create an AI agent using AI Hub, the class needs to do the following:
    - Use `%AI.Agent` as a superclass
    - Define a model/provider configuration for the LLM.

This file has done these steps for us. The model config is named with the `MODELCONFIG` parameter, while the provider is set with a custom `%OnInit` method. Here, the credentials are accessed from the config store, a feature being released with the AI Hub.


## Trying out the agent

To test the agent, open the [Shell](tab-1) tab and do the following:

- Instantiate the agent with `.%New()`
- Initialise the agent with `.%Init()`
- Create a session with `.CreateSession()`
- Chat agent using `.Chat(session, prompt)`
- Print output from `response.Content`. For better rendering use `##class(%AI.System).RenderMarkdown`

<details>
<summary>Hint</summary>

```objectscript
// Instantiate
set agent = ##class(Warehouse.AI.Agent).%New()

// Initialise
set sc = agent.%Init()

// Create session
set session = agent.CreateSession()

// Chat
set response = agent.Chat(session, "Tell me a joke")

// Render response
do ##class(%AI.System).RenderMarkdown(response.Content)
```

</details>

## Adding a system prompt

To customise the agent, you can add a system prompt. This can be done in an `XData` block with `[MimeType="text/markdown"]` to use markdown. Add the following XData block:


```ObjectScript
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


            Your response must begin with { and end with }, and only include correctly formatted JSON data. Do not include code fences or any other text outside of the JSON.

    }

```

Save the changes and ensure that the class compiles (you should see a little pop-up saying "Compiling Class..." in the right hand corner).


### Testing the unstructured -> structured transition

Now we have our agent with custom instructions to output a structured response, lets see how it does.

We have a helper function which will yield emails as strings, which we will develop with before connecting the agent to our mailbox:

```objectscript

// To get the email as a string
set email = ##class(Warehouse.Utils.Emails).ReturnEmailString(1)


// To view the email

do ##class(Warehouse.Utils.Emails).PrintEmail(1)
```

Try, using the syntax given above, prompt the agent with the email above:


<details>
<summary>Hint</summary>

```objectscript
set email = ##class(Warehouse.Utils.Emails).ReturnEmailString(1)

set agent = ##class(Warehouse.AI.Agent).%New()
set sc = agent.%Init()
set session = agent.CreateSession()
set response = agent.Chat(session, email)

write response.Content
```

</details>

Despite our best efforts with the system prompt, sometimes the agent returns text either side of the JSON output. We could upgrade the model to a better (more expensive) model, but this can also be handled with a utility method (feel free to take a look at the contents):

```
set obj = ##class(Warehouse.Utils.JSON).ExtractJSON(response.Content)
```

So now try:

```
zwrite obj
```

You should have a structured response!


The agent can be further customised with tools, skills and knowledge bases. The next step will show how to create and add tools to the agent.



