# ai-hub-datasummit

InterSystems IRIS interoperability demo. Inbound emails are parsed by an LLM agent, categorised, and routed to downstream operations — including an order-processing agent and a human review queue.

## Architecture

```
mailpit (POP3:1110)
  -> FromEmail            [BusinessService, EnsLib.EMail.InboundAdapter]
      -> Router           [BusinessProcess]
          -> ToEmailParsingAgent  [BO, sync]  <- EmailParser agent (LLM)
          -> ToOrderAgent         [BO, async] <- OrderAgent agent (LLM + tools)
          -> ToHumanReview        [BO, async] <- stub, receives non-order / flagged messages
```

### Key classes

| Class | Role |
|---|---|
| `Warehouse.Interop.FromEmail` | Receives POP3 mail, wraps in `MailMessage`, sends to Router |
| `Warehouse.Interop.Router` | BP; sends to EmailParser first, then routes on `Category` |
| `Warehouse.Interop.BO.ToEmailParsingAgent` | Calls the EmailParser agent, sets `Category` on message |
| `Warehouse.Interop.BO.ToOrderAgent` | Calls the OrderAgent agent, parses structured JSON response, routes to HumanReview if `ReviewRequired` |
| `Warehouse.Interop.BO.ToHumanReview` | Receives `ReviewRequest` messages for human action (stub) |
| `Warehouse.AI.Agent` | Single `%AI.Agent` class (post-refactor, replaces the old `Warehouse.AI.Agents.*` split of `BaseAgent`/`EmailParser`/`OrderAgent`); model config `bedrock.claude-haiku-4-5`; loads provider/model from `%ConfigStore.Configuration` in `%OnInit`; tool sets via `TOOLSETS` param; has `ProcessEmail()` entry point |
| `Warehouse.AI.ToolSet` | `%AI.ToolSet`; includes `LookupTools` and `OrderTools`; audited via `Warehouse.AI.ConsoleAudit` |
| `Warehouse.AI.LookupTools` | `%AI.Tool`; SQL-backed queries: `LookUpCustomer`, `GetProducts`, `GetOrders` |
| `Warehouse.AI.OrderTools` | `%AI.Tool`; stateful draft-order flow: `CreateDraftOrder` -> `ValidateDraftOrder` -> `SubmitDraftOrder`, backed by `Warehouse.Data.DraftOrder` |
| `Warehouse.AI.ConsoleAudit` | `%AI.Policy.Audit`; logs each tool call (name, args, result, duration) to console |
| `Warehouse.Utils.JSON` | `ExtractJSON()` — strips markdown/commentary noise from LLM output down to the outermost `{...}` span before `%FromJSON` |
| `Warehouse.Utils.ConfigStore` | Sets up `%Wallet` secret + `%ConfigStore.Configuration` entries for the Bedrock LLM config (reads `AWS_BEARER_TOKEN_BEDROCK`) |
| `Warehouse.Interop.Messages.MailMessage` | Core message; extends `Ens.MessageBody` + `%JSON.Adaptor` |
| `Warehouse.Interop.Messages.ReviewRequest` | Extends `MailMessage`; adds `AgentNotes` and `ReviewReason` |
| `Warehouse.Data.DraftOrder` | Extends `Warehouse.Data.Order`; adds `ReviewRequired`; used by `OrderTools` during the draft-order flow before/instead of a committed `Order` |

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

When `ReviewRequired` is true, `ToOrderAgent` sends a `ReviewRequest` (with `AgentNotes` and `ReviewReason` populated) to `ToHumanReview` async.

### Data model (`Warehouse.Data.*`)

Persistent classes: `Customer` (CustomerId, ContactEmail, Status, Trusted, DefaultDeliveryAddress), `Product` (SKU, Active, Quantity, UnitPrice), `Order`/`DraftOrder` (order history + in-flight draft awaiting validation/submission), `Transactions`.

Note: `ContractPrice`, `Supplier`, `SupplierProduct`, `StockMovement`, and `OrderItem` were removed in the "Major refactor for take 2" — the data model is now simpler (no per-customer contract pricing, no supplier tracking, orders are not itemised as separate child records).

Sample data (`Warehouse.Utils.PopulateDemo.PopulateAll()`) and sample emails (`Warehouse.Utils.Emails`) — check current contents directly, as these were touched in the refactor and may no longer match the customer/product IDs described in earlier docs.

## Infrastructure

- **IRIS**: port 52773 (web), 1972 (superserver), 8080
- **mailpit**: port 8025 (web UI), 1025 (SMTP), 1110 (POP3)
- Credentials stored in IRIS: `do ##class(Ens.Config.Credentials).SetCredential("mailpit", "iris", "test123")`
- AWS credentials: `AWS_BEARER_TOKEN_BEDROCK` env var, wrapped into a `%Wallet` secret and referenced from `%ConfigStore.Configuration` (see `Warehouse.Utils.ConfigStore`)

## Instruqt workshop (`instruqt/ai-hub-workshop/`)

Initial draft scripts/content for an Instruqt hands-on lab track built on this demo: `track.yml`, `config.yml`, and assignment steps `01-introduction` through `06-extension` (create an agent, add tools, give autonomy, add to interop, extension). Steps 02-04 (`create-an-agent`, `add-tools`, `give-autonomy`) have been reconciled against the current `Warehouse.AI.*` classes (correct class names, method signatures, and `ToolSet` XML). `05-adding-to-interop` and `06-extension` are still placeholder/stub content.

## Current state / known gaps

- **Stale class references after the AI refactor**: `Warehouse.Interop.BO.ToOrderAgent` and `Warehouse.Interop.BO.ToEmailParsingAgent` still reference `Warehouse.AI.Agents.OrderAgent`, `Warehouse.AI.Agents.EmailParser`, and `Warehouse.AI.BaseAgent.ExtractJSON` — none of which exist anymore (replaced by the single `Warehouse.AI.Agent` and `Warehouse.Utils.JSON.ExtractJSON`). These BOs need updating to use the new class.
- `ToHumanReview` has an empty MessageMap — stub only.
- `SupportTarget` routing exists in the Router but no BO has been created for it.
- `05-adding-to-interop` and `06-extension` Instruqt steps are still stubs with no real content.
