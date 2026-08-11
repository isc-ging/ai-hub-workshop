# Workshop Spec: Governed Procurement Agent with InterSystems AI Hub

50-minute hands-on workshop. Five challenges, same agent, each challenge adds one capability with an immediately visible behaviour change.

## Quick reference: what's next

| # | Challenge | Time | New tools | Outcome |
|---|---|---|---|---|
| 1 | [Structured intent](#challenge-1-turn-an-email-into-structured-intent) | 8 min | none | Email -> structured JSON, no lookups |
| 2 | [Lookup tools](#challenge-2-give-the-agent-lookup-tools) | 8 min | `FindCustomer`, `GetProduct` | Enriches result with authoritative IDs |
| 3 | [Ambiguous request](#challenge-3-resolve-an-ambiguous-request) | 9 min | `GetRecentOrders` | Resolves references, still flags missing quantity |
| 4 | [Controlled write](#challenge-4-allow-a-controlled-business-action) | 9 min | `GetContractPrice`, `CreateDraftOrder` | Creates a draft order |
| 5 | [Policy + approval](#challenge-5-add-policies-and-human-approval) | 8 min | `RequestHumanApproval` | Escalates instead of acting when out of authority |
| - | [Final demo](#final-demonstration) | 3 min | - | Run all 3 outcomes back to back |

**Participant-owned files:** `Demo.ProcurementAgent`, `Demo.ProcurementTools` only. Everything else (services, data model, test harness) is pre-built.

**Target edit size per challenge:** 5-15 lines.

---

## Scenario

Participants build a Procurement Agent that reads unstructured customer emails and:

1. Converts the email into a structured business intent.
2. Looks up customer, product and order data via tools.
3. Resolves references (e.g. "the usual warehouse", "last time's order").
4. Creates a draft order when it has enough information.
5. Applies business policy and escalates to a human when it doesn't.

## Learning objectives

Participants should leave able to:

- Create an agent with the AI Hub SDK.
- Define agent instructions and request structured output.
- Expose IRIS data/logic as agent tools.
- Let an agent choose and sequence tools dynamically.
- Separate agent reasoning from deterministic business operations.
- Permit controlled write operations.
- Apply policy/approval boundaries to agent actions.
- Inspect agent activity via tool calls and final result.

---

## Environment (provided, not built by participants)

- IRIS instance with AI Hub installed + configured LLM provider.
- Sample procurement database.
- Starter ObjectScript classes.
- Browser UI or terminal test harness.
- Five sample customer emails.
- Trace view of agent activity.
- A recovery checkpoint per challenge (see [Checkpoints](#workshop-checkpoints)).

Participants never configure credentials, deploy containers, or create schemas.

### Sample data

**Customers**

| ID | Name |
|---|---|
| C1001 | Northwind Heating Ltd |
| C1002 | Alpine Facilities |
| C1003 | Citywide Engineering |

**Products**

| SKU | Description |
|---|---|
| TS-400 | Industrial temperature sensor |
| TS-450 | High-accuracy temperature sensor |
| GW-10 | Sensor gateway |
| CBL-5M | Five-metre extension cable |

**Order history**

- Northwind Heating Ltd: 20 x TS-400 @ £72/unit, delivered to Edinburgh Warehouse.
- Alpine Facilities: 10 x TS-450 @ £105/unit, delivered to Glasgow Depot.

**Policies**

- Agent may create draft orders; may not confirm/dispatch.
- Orders above £2,000 require human approval.
- Delivery address changes always require human approval.
- Quantity must not be inferred unless an active recurring-order agreement exists.
- Unknown customers must be escalated.

## Common agent result shape

Same output structure throughout; fields fill in progressively.

```json
{
  "intent": "place_order",
  "status": "information_required",
  "customerId": null,
  "customerName": "Northwind Heating",
  "items": [
    { "productId": null, "description": "temperature sensors", "quantity": 20, "unitPrice": null }
  ],
  "requestedDeliveryDate": null,
  "requestedDeliveryAddress": null,
  "draftOrderId": null,
  "requiresHumanApproval": false,
  "approvalReason": null,
  "missingInformation": ["Exact product could not be identified"],
  "summary": "Northwind Heating requested 20 temperature sensors.",
  "actionsTaken": []
}
```

**Intent values:** `place_order`, `amend_order`, `cancel_order`, `request_information`, `unknown`
**Status values:** `understood`, `information_required`, `draft_created`, `awaiting_approval`, `rejected`, `unable_to_process`

Schema is provided to participants, not designed by them.

---

## Challenge 1: Turn an Email into Structured Intent

**Time:** 8 min · **New tools:** none

**Objective:** Create the Procurement Agent and instruct it to convert an unstructured email into the structured result format.

**Test email**
```
From: purchasing@northwind.example
Subject: Temperature sensors

Could you arrange an order for 20 of the TS-400 temperature sensors?
Please send them to our usual warehouse.
Thanks, Sarah
```

**Task**
- Select the configured model.
- Write agent instructions.
- Require the structured output format.
- Run the email through the test harness.

Instructions must cover: agent's role, supported intents, extractable fields, no invented data, how to report uncertainty, and that it has no tools yet.

**Suggested instructions**
```
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
```

**Expected result**
```json
{
  "intent": "place_order",
  "status": "information_required",
  "customerName": "Northwind",
  "items": [{ "productId": "TS-400", "quantity": 20 }],
  "missingInformation": ["Delivery address must be resolved"],
  "actionsTaken": []
}
```

**Key point:** unstructured text -> predictable contract, but without tools the agent only knows what's in the message.

**Done when:** output is valid, intent correct, missing info explicit, nothing fabricated.

---

## Challenge 2: Give the Agent Lookup Tools

**Time:** 8 min · **New tools:** `FindCustomer`, `GetProduct`

**Objective:** Connect the agent to live enterprise data.

| Tool | Inputs | Result |
|---|---|---|
| `FindCustomer` | `name`, `emailAddress` | `{"customerId":"C1001","customerName":"Northwind Heating Ltd","status":"active","defaultDeliveryAddress":"Edinburgh Warehouse"}` |
| `GetProduct` | `productId`, `description` | `{"productId":"TS-400","productName":"Industrial temperature sensor","active":true,"standardPrice":80.00}` |

**Task**
- Add both tools to the agent's toolset.
- Expose the (already-implemented) lookup methods as AI Hub tools with clear descriptions.
- Re-run the Challenge 1 email.
- Inspect the tool-call trace.

**Expected agent activity**
1. Call `FindCustomer` on the sender address.
2. Call `GetProduct("TS-400")`.
3. Use the customer record to resolve "usual warehouse".
4. Return an enriched result.

**Expected result**
```json
{
  "intent": "place_order",
  "status": "understood",
  "customerId": "C1001",
  "customerName": "Northwind Heating Ltd",
  "items": [{ "productId": "TS-400", "description": "Industrial temperature sensor", "quantity": 20 }],
  "requestedDeliveryAddress": "Edinburgh Warehouse",
  "missingInformation": [],
  "actionsTaken": ["customer_resolved", "product_resolved", "delivery_address_resolved"]
}
```

**Discussion prompt:** Why should customer/product data come from tools, not the model? -> authoritative systems, not model memory.

**Done when:** agent autonomously calls both tools, params derived from the email, output has authoritative IDs, trace shows the calls.

---

## Challenge 3: Resolve an Ambiguous Request

**Time:** 9 min · **New tool:** `GetRecentOrders`

**Objective:** Force multi-tool selection/sequencing, not just field extraction.

**Test email** (no product ID, quantity, full name, or address)
```
From: purchasing@northwind.example
Subject: Repeat order

Can we have another batch of the temperature sensors we ordered last time?
We need them at the usual location.
Thanks, Sarah
```

**Tool:** `GetRecentOrders` — inputs `customerId`, `maximumResults` — returns order history including `productId`, `quantity`, `deliveryAddress`.

**Task**
- Expose `GetRecentOrders`, add to toolset.
- Update instructions to explain how order history may be used.
- Run the ambiguous email, review the tool-call sequence.

**Required rule:** the agent may use history to resolve a *product* reference, but must **not** infer quantity from a past order unless the customer explicitly asks for the same amount or a recurring-order agreement exists. (Resolving a reference vs. making an unsupported assumption.)

**Expected agent activity**
1. `FindCustomer` on sender address.
2. `GetRecentOrders` for that customer.
3. Infer TS-400 from "temperature sensors" + history.
4. Resolve delivery address from history.
5. Recognise quantity is still unspecified.
6. Return `information_required`.

**Expected result**
```json
{
  "intent": "place_order",
  "status": "information_required",
  "customerId": "C1001",
  "items": [{ "productId": "TS-400", "description": "Industrial temperature sensor", "quantity": null }],
  "requestedDeliveryAddress": "Edinburgh Warehouse",
  "missingInformation": ["Order quantity"],
  "summary": "The customer appears to be requesting TS-400 sensors, based on their most recent order. The requested quantity is not explicit.",
  "actionsTaken": ["customer_resolved", "order_history_checked", "product_resolved_from_previous_order", "delivery_address_resolved"]
}
```

**Optional comparison email** (if time permits): "Please repeat our last order for the temperature sensors, with the same quantity." Here the agent may reuse quantity too, since repetition is explicit.

**Key point:** agentic behaviour matters once extraction alone isn't enough — the agent must decide what's missing, which tools to call, and which conclusions are actually justified.

**Done when:** agent sequences customer + order-history tools, resolves product from history, does not silently infer quantity, states the remaining gap clearly.

---

## Challenge 4: Allow a Controlled Business Action

**Time:** 9 min · **New tools:** `GetContractPrice`, `CreateDraftOrder`

**Objective:** Move from read-only to a controlled write.

| Tool | Inputs | Result |
|---|---|---|
| `GetContractPrice` | `customerId`, `productId`, `quantity` | `{"unitPrice":72.00,"quantity":20,"totalPrice":1440.00,"currency":"GBP","pricingSource":"customer_contract"}` |
| `CreateDraftOrder` | `customerId`, `items`, `deliveryAddress` | `{"draftOrderId":"DRAFT-2031","status":"draft","totalPrice":1440.00,"currency":"GBP"}` |

**Design constraint:** creates a *draft*, never a confirmed order — reversible, reviewable, safe, bounded. The tool validates required fields itself; the agent isn't solely responsible for data integrity.

**Test email**
```
From: purchasing@northwind.example
Subject: Order request

Please order 20 TS-400 temperature sensors and send them to our usual warehouse.
Thanks, Sarah
```

**Task**
- Add both tools.
- Update instructions: a draft may only be created once customer is active, product is valid, quantity is explicit, delivery address is resolved, and contract pricing is retrieved.
- Run the test email; confirm a draft record lands in IRIS.

**Expected agent activity**
1. Resolve customer -> 2. Resolve product -> 3. Resolve delivery address -> 4. Retrieve contract price -> 5. Confirm all required info present -> 6. `CreateDraftOrder` -> 7. Return draft reference.

**Expected result**
```json
{
  "intent": "place_order",
  "status": "draft_created",
  "customerId": "C1001",
  "items": [{ "productId": "TS-400", "quantity": 20, "unitPrice": 72.00 }],
  "requestedDeliveryAddress": "Edinburgh Warehouse",
  "draftOrderId": "DRAFT-2031",
  "requiresHumanApproval": false,
  "summary": "A draft order for 20 TS-400 sensors has been created with a total value of £1,440.",
  "actionsTaken": ["customer_resolved", "product_resolved", "contract_price_retrieved", "draft_order_created"]
}
```

**Failure-path test:** "Please order 20 TS-999 sensors." -> product lookup fails -> agent must **not** call `CreateDraftOrder`.

**Key point:** the agent decides *when* to request an action; the tool stays responsible for deterministic validation and DB writes.

**Done when:** pricing is retrieved before the draft, a valid request creates exactly one draft, the response includes the draft reference, invalid/incomplete requests create nothing.

---

## Challenge 5: Add Policies and Human Approval

**Time:** 8 min · **New tool:** `RequestHumanApproval`

**Objective:** Enforce enterprise governance — the agent must know its authority boundary.

**Tool:** `RequestHumanApproval` — inputs `requestType`, `customerId`, `summary`, `reason`, `proposedAction`, `estimatedValue` — returns `{"reviewId":"REV-5014","status":"awaiting_review","assignedQueue":"Procurement Approvals"}`.

**Policy — require approval when:**
- Order value exceeds £2,000.
- Customer requests a delivery-address change.
- Customer can't be verified.
- Product reference is ambiguous.
- Action is cancellation or amendment of an existing order.

**Task:** configure the agent to route these cases to the approval tool.

### Test email A — value threshold
```
Please order 40 TS-400 temperature sensors and send them to our usual warehouse.
```
At £72/unit that's £2,880 — over the limit.

Expected activity: resolve customer -> resolve product -> get contract price -> compute total -> detect over-limit -> **skip** draft creation -> call `RequestHumanApproval`.

```json
{
  "intent": "place_order",
  "status": "awaiting_approval",
  "customerId": "C1001",
  "requiresHumanApproval": true,
  "approvalReason": "Order value exceeds the agent's £2,000 authority limit",
  "summary": "The requested order is valued at £2,880 and has been submitted for human approval.",
  "actionsTaken": ["customer_resolved", "product_resolved", "contract_price_retrieved", "human_approval_requested"]
}
```

### Test email B — address change
```
Please order 20 TS-400 sensors. Do not use our usual warehouse. Send them to:
Temporary Project Site, 14 Example Road, Edinburgh
```
Below the value threshold, but the address-change policy still requires approval. Agent must: detect the address differs from the approved one, avoid updating the customer record, avoid creating the draft, create a review request, and state which policy fired.

**Implementation principle:** don't rely solely on the prompt for enforcement.
- `CreateDraftOrder` should itself reject orders above the autonomous threshold.
- Address validation should check against approved customer addresses in code.
- Tool access should be role-gated.

This separates: **agent instructions** (what it's expected to do) vs **tool validation** (prevents invalid ops regardless of model behaviour) vs **access control** (whether the caller may use the operation at all).

**Key point:** enterprise agency = bounded autonomy — act inside enforced limits, escalate everything else.

**Done when:** agent identifies at least two distinct approval conditions, doesn't draft when approval is needed, creates a review record with a clear reason, trace exposes the policy decision.

---

## Final Demonstration

**Time:** 3 min. Run three emails back to back:

| Email | Expected outcome |
|---|---|
| "Please order 20 TS-400 sensors and send them to our usual warehouse." | Draft created |
| "Please send another batch of the sensors we ordered last time." | Information required: quantity |
| "Please order 40 TS-400 sensors." | Human approval requested |

Highlight: same agent, different paths, driven by available information, retrieved data, tool results, policy, and authority level.

## Agent Activity View

Trace should show observable events only (tool calls, tool results, policy outcomes) — never private model reasoning. Example:

```
Received email from purchasing@northwind.example
Intent identified: place_order
Tool call: FindCustomer(emailAddress="purchasing@northwind.example")
Tool result: Customer C1001, Northwind Heating Ltd, status active
Tool call: GetProduct(productId="TS-400")
Tool result: Industrial temperature sensor, active
Tool call: GetContractPrice(customerId="C1001", productId="TS-400", quantity=40)
Tool result: £72 per unit, £2,880 total
Policy decision: Order exceeds autonomous threshold of £2,000
Tool call: RequestHumanApproval(requestType="high_value_order", customerId="C1001", estimatedValue=2880)
Final status: awaiting_approval
```

## Starter Project Structure

```
src/Demo/
  ProcurementAgent.cls        <- participant-owned
  ProcurementTools.cls        <- participant-owned
  ProcurementPolicy.cls
  ProcurementResult.cls
  Data/
    Customer.cls  Product.cls  Order.cls  OrderItem.cls  ReviewRequest.cls
  Services/
    CustomerService.cls  ProductService.cls  PricingService.cls
    OrderService.cls  ApprovalService.cls
  Tests/
    WorkshopRunner.cls  SampleEmails.cls
```

Service classes are pre-built and tested so workshop time stays on agent definition, tool exposure, and policy-aware orchestration — not SQL/persistence/UI.

## Workshop Checkpoints

`checkpoint-0-starter` -> `checkpoint-1-structured-intent` -> `checkpoint-2-lookup-tools` -> `checkpoint-3-ambiguous-request` -> `checkpoint-4-draft-order` -> `checkpoint-5-governed-agent`

A participant who falls behind can jump to the next checkpoint without losing the rest of the workshop. Each checkpoint bundles: a working solution for the previous challenge, next challenge's instructions, a known-good test email + expected result, and one deliberately failing test.

## Facilitator Guidance

Per challenge: explain the problem -> show the missing capability -> give the coding task -> run the test -> discuss the changed behaviour. Introduce each AI Hub concept right before it's used, not up front.

**Suggested transitions**

| Before | Say |
|---|---|
| Challenge 1 | "The agent currently receives text. Its first responsibility is to turn that text into an application-friendly contract." |
| Challenge 2 | "The result contains uncertainty because the model only knows what was written. We'll now connect it to authoritative enterprise data." |
| Challenge 3 | "Direct lookups work with exact identifiers. Real requests often rely on shared business context, like 'the product we ordered last time.'" |
| Challenge 4 | "The agent can now understand and investigate a request. We'll give it a limited ability to act." |
| Challenge 5 | "Allowing an agent to act isn't the same as allowing it to do anything. We'll now define and enforce its authority boundary." |

## Scope Controls (avoid asking participants to)

- Write DB queries from scratch, build a UI, configure an LLM provider, create/load sample data, define the full response schema, implement order persistence, debug auth/networking, write a large production prompt, or build every tool method from scratch.

Participants should instead complete small blocks: an agent declaration, a concise instruction section, tool exposure metadata, tool descriptions, assigning a toolset, one or two policy rules. Target: 5-15 lines changed per challenge.

## Workshop Success Criteria

Participants should be able to explain by the end:

- The model interprets the request.
- The agent decides what information/actions are needed.
- Tools provide authoritative data and controlled operations.
- Policies determine the boundary of autonomous action.
- IRIS stores data, executes business logic, and records the outcome.

The final solution demonstrates all four outcomes: request understood, information required, draft created, human approval required. Most importantly, participants should have directly watched the agent receive an unstructured request, select tools, sequence multiple calls, perform a controlled action, and stop/escalate at its authority boundary.
