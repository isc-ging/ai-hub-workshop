# ai-hub-datasummit

InterSystems IRIS interoperability demo. Inbound emails are parsed by an LLM agent, categorised, and routed to downstream operations — including an order-processing agent and a human review queue.

## Architecture

```
mailpit (POP3:1110)
  -> FromEmail            [BusinessService, EnsLib.EMail.InboundAdapter]
      -> Router           [BusinessProcess]
          -> ToEmailParsingAgent  [BO, sync]  <- EmailParser LLM
          -> ToOrderAgent         [BO, async] <- OrderAgent LLM + tools
          -> ToHumanReview        [BO, async] <- stub, receives non-order / flagged messages
```

### Key classes

| Class | Role |
|---|---|
| `Warehouse.Interop.FromEmail` | Receives POP3 mail, wraps in `MailMessage`, sends to Router |
| `Warehouse.Interop.Router` | BP; sends to EmailParser first, then routes on `Category` |
| `Warehouse.Interop.BO.ToEmailParsingAgent` | Calls `EmailParser` agent, sets `Category` on message |
| `Warehouse.Interop.BO.ToOrderAgent` | Calls `OrderAgent` agent, parses structured JSON response, routes to HumanReview if `ReviewRequired` |
| `Warehouse.Interop.BO.ToHumanReview` | Receives `ReviewRequest` messages for human action (stub) |
| `Warehouse.AI.Agents.BaseAgent` | Base `%AI.Agent`; model = `us.anthropic.claude-haiku-4-5`; provider = AWS Bedrock us-east-1 |
| `Warehouse.AI.Agents.EmailParser` | Classifies email into `Order`, `Support`, `Invoice`, or `Other`; returns JSON only |
| `Warehouse.AI.Agents.OrderAgent` | Checks stock + customer trust; returns JSON with `ReviewRequired`, `Order`, `ReasonForReview`, `AgentNotes` |
| `Warehouse.AI.OrderTools` | `%AI.Tool`; tools: `GetStock`, `LookUpCustomer`, `ProcessTransaction` |
| `Warehouse.Interop.Messages.MailMessage` | Core message; extends `Ens.MessageBody` + `%JSON.Adaptor` |
| `Warehouse.Interop.Messages.ReviewRequest` | Extends `MailMessage`; adds `AgentNotes` and `ReviewReason` |

### Router category mapping

| Category | Target property | Default destination |
|---|---|---|
| `Order` | `OrderTarget` | `ToOrderAgent` |
| `Support` | `SupportTarget` | (not yet wired) |
| `Other` / default | `HumanTarget` | `ToHumanReview` |

### OrderAgent JSON response shape

```json
{
  "ReviewRequired": 1,
  "Order": [{"productId": "sku-123", "quantity": "5", "currentStock": 2}],
  "ReasonForReview": "OutOfStock|UntrustedCustomer|NewCustomer|Other",
  "AgentNotes": "..."
}
```

When `ReviewRequired` is true, `ToOrderAgent` should send a `ReviewRequest` (with `AgentNotes` and `ReviewReason` populated) to `ToHumanReview`.

### Data model (`Warehouse.Data.*`)

Persistent classes: `Customer` (CustomerId, ContactEmail, Status, Trusted, DefaultDeliveryAddress), `Product` (SKU, Active, Quantity, UnitPrice), `Order`/`OrderItem` (order history, parent/child), `ContractPrice` (per customer+product negotiated price), `Supplier`/`SupplierProduct`, `StockMovement`, `Transactions`.

Sample data (`Warehouse.Utils.PopulateDemo.PopulateAll()`): sensor products (TS-400, TS-450, GW-10, CBL-5M) and three customers (C1001 Northwind Heating, C1002 Alpine Facilities, C1003 Citywide Engineering) with contract prices and one order-history record each. Sample emails in `Warehouse.Utils.Emails`.

## Infrastructure

- **IRIS**: port 52773 (web), 1972 (superserver), 8080
- **mailpit**: port 8025 (web UI), 1025 (SMTP), 1110 (POP3)
- Credentials stored in IRIS: `do ##class(Ens.Config.Credentials).SetCredential("mailpit", "iris", "test123")`
- AWS credentials: `AWS_BEARER_TOKEN_BEDROCK` env var (read by `BaseAgent.%OnInit`)

## Current state / known gaps

- `ToOrderAgent` parses the JSON response but does not yet act on it (the `if output.ReviewRequired` block is empty).
- `ToHumanReview` has an empty MessageMap — stub only.
- `SupportTarget` routing exists in the Router but no BO has been created for it.
- `Warehouse.AI.OrderTools.LookUpCustomer` queries a nonexistent `Email` column on `Warehouse.Data.Customer` (should be `ContactEmail`).

