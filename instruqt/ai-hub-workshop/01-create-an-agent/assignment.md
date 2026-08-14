---
slug: create-an-agent
id: mielhz28oe7q
type: challenge
title: Creating an Agent
notes:
- type: text
  contents: |-
    The AI Hub is a new feature coming to InterSystems IRIS in 2026. One of the new features it introduces is a new ObjectScript SDK for using Large Language Models, creating Agents and exposing business logic as Model Context Protocol servers.
    > **Click the right arrow to keep reading >**
- type: text
  contents: |-
    In this workshop, we will see how an agent can be used to read emails requesting product orders for an industrial supplies company.

    Unstructured email data will be passed to the agent. The agent will read the email and turn this into structured data. Later, we will expand the abilities of this agent by adding custom tools, giving it controlled access to our InterSystems IRIS database and codebase.

    > **Click Start in the right hand corner to begin**
tabs:
- id: fczjsuebbsdp
  title: Code
  type: service
  hostname: ai-hub-eap
  path: ?folder=/home/irisowner/ai-hub-workshop/src/EmailAI
  port: 8888
- id: 10k766ictt9z
  title: Shell
  type: terminal
  hostname: ai-hub-eap
  cmd: su - irisowner -s /usr/irissys/bin/iris session iris
difficulty: ""
enhanced_loading: null
---

Let's start by creating our basic agent. Open the [VS Code](tab-0) tab, then open the file `src/EmailAI/Agent.cls`

To create an AI agent using AI Hub, the class needs to do the following:
- Use `%AI.Agent` as a superclass
- Define a model/provider configuration for the LLM.

The class here has already taken these steps. We are accessing a pre-defined configuration that is saved in the new InterSystems IRIS  ConfigStore, which we are collecting with the model parameter. It is easy to connect to a wide range of LLM providers though.

**Task 1: Test the agent**

Begin by seeing that the agent class works. Open the [Shell](tab-1) Follow the sequence below (expand the `hint` section to see the full syntax).

- Instantiate the agent with `.%New()`
- Initialise the agent with `.%Init()`
- Create a session with `.CreateSession()`
- Chat agent using `.Chat(session, "Tell me a joke")`. You can add any prompt here, this is a general test example.
- Print output from `response.Content`. For better rendering use `##class(%AI.System).RenderMarkdown`

<details>
<summary style="color:#FFA489;font-weight:bold;">Hint</summary>

```objectscript,run
// Instantiate
set agent = ##class(EmailAI.Agent).%New()

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

**Task 2: Adding a System Prompt**

To customise the agent, you can add a system prompt. This is done with an `XData` block called `INSTRUCTIONS`. We can use markdown in this block by using the keyword option `[MimeType = "text/markdown]`.

To save time on prompt engineering, the prompt has been written for you:

```markdown
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
```

Add this to the agent class in an XData block and save the changes. Ensure that the class compiles (you should see a little pop-up saying "Compiling Class..." in the right hand corner), or failing this, right click on the file in the explorer and choose `Import and Compile`.

<details><summary style="color:#FFA489;font-weight:bold;">Hint</summary>
Add the following to Agents.cls:

```
XData INSTRUCTIONS [MimeType = "text/markdown"]{
  // System prompt given above
}
```

</details>


## Task 3: Test the agent again

Now we have our agent with custom instructions to output a structured response, lets see how it does.

We have a helper function which will yield emails as strings, which we will develop with before connecting the agent to our mailbox.

First, take a look at the test email again:

```run
do ##class(Utils.Emails).PrintEmail(1)
```

Then, save the email to a string variable:

```run
set email = ##class(Utils.Emails).ReturnEmailString(1)
```

Then re-create the agent with the commands given above (or check the hint section below). This time use the email string as a prompt, and take a look at the output.


<details>
<summary style="color:#FFA489;font-weight:bold;">Hint</summary>

```objectscript
set email = ##class(Utils.Emails).ReturnEmailString(1)

set agent = ##class(EmailAI.Agent).%New()
set sc = agent.%Init()
set session = agent.CreateSession()
set response = agent.Chat(session, email)

write response.Content
```

</details>


## Task 4: Parsing the response

In an ideal world, the agent would consistently reply with only JSON data. This way we could run `{}.%FromJSON(response.Content)` to parse it into an object. However, LLMs are non-deterministic and often add 'code fences (```)' around JSON blocks which can be problematic. Luckily, its quite easy to define a utility function which can strip these to create a Dynamic Object output. We can run the following:

```run
set obj = ##class(Utils.JSON).ExtractJSON(response.Content)
```

So now try:

```run
zwrite obj
```

You should have a structured response!


The agent can be further customised with tools, skills and knowledge bases. The next step will show how to create and add tools to the agent.



