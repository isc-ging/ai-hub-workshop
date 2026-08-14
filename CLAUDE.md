# ai-hub-datasummit

InterSystems IRIS interoperability demo. Inbound emails are parsed by an LLM agent, categorised, and routed to downstream operations — including an order-processing agent and a human review queue.

## Architecture

```
mailpit (POP3:1110)
  -> EmailInterop.FromEmail       [BusinessService, EnsLib.EMail.InboundAdapter]
      -> EmailInterop.Router      [BusinessProcess]
          -> ToEmailParsingAgent  [BO, sync]  <- EmailAI.Agent (LLM)
          -> ToOrderAgent         [BO, async] <- EmailAI.Agent (LLM + tools)
          -> ToHumanReview        [BO, async] <- receives non-order / flagged messages
```

### Key classes

| Class | Role |
|---|---|
| `EmailInterop.FromEmail` | Receives POP3 mail, wraps in `MailMessage`, sends to Router |
| `EmailInterop.Router` | BP; sends to EmailParser first, then routes on `Category` |
| `EmailInterop.BO.ToEmailParsingAgent` | Calls the agent, sets `Category` on message |
| `EmailInterop.BO.ToOrderAgent` | Calls the agent, parses structured JSON response, routes to HumanReview if `ReviewRequired` |
| `EmailInterop.BO.ToHumanReview` | Receives `ReviewRequest` messages for human action; sends review email via SMTP |
| `EmailAI.Agent` | Single `%AI.Agent` class; model config `bedrock.claude-haiku-4-5`; loads provider/model from `%ConfigStore.Configuration` in `%OnInit`; tool sets via `TOOLSETS` param; has `ProcessEmail()` entry point |
| `EmailAI.ToolSet` | `%AI.ToolSet`; includes `LookupTools` and `OrderTools`; audited via `EmailAI.ConsoleAudit` |
| `EmailAI.LookupTools` | `%AI.Tool`; SQL-backed queries: `LookUpCustomer`, `GetProducts`, `GetOrders` |
| `EmailAI.OrderTools` | `%AI.Tool`; stateful draft-order flow: `PrepareOrder` -> `SubmitDraftOrder`, backed by `Warehouse.DraftOrder` |
| `EmailAI.ConsoleAudit` | `%AI.Policy.Audit`; logs each tool call (name, args, result, duration) to console |
| `Utils.JSON` | `ExtractJSON()` — strips markdown/commentary noise from LLM output down to the outermost `{...}` span before `%FromJSON` |
| `Utils.ConfigStore` | Sets up `%Wallet` secret + `%ConfigStore.Configuration` entries for the Bedrock LLM config (reads `AWS_BEARER_TOKEN_BEDROCK`) |
| `Utils.Emails` | Sample emails for testing; use `ReturnEmailString(n)` or `PrintEmail(n)` |
| `Utils.PopulateDemo` | `PopulateAll()` seeds Customer, Product, Order data |
| `EmailInterop.Messages.MailMessage` | Core message; extends `Ens.MessageBody` + `%JSON.Adaptor` |
| `EmailInterop.Messages.ReviewRequest` | Extends `MailMessage`; adds `AgentNotes` and `ReviewReason` |
| `Warehouse.DraftOrder` | Extends `Warehouse.Order`; adds `ReviewRequired`; used by `OrderTools` during the draft-order flow |

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

### Data model (`Warehouse.*`)

Persistent classes: `Warehouse.Customer` (CustomerId, ContactEmail, Status, Trusted, DefaultDeliveryAddress), `Warehouse.Product` (SKU, Active, Quantity, UnitPrice), `Warehouse.Order`/`Warehouse.DraftOrder` (order history + in-flight draft), `Warehouse.Transactions`.

SQL table names use the package prefix, e.g. `FROM Warehouse.Customer`.

## Infrastructure

- **IRIS**: port 52773 (web), 1972 (superserver), 8080
- **mailpit**: port 8025 (web UI), 1025 (SMTP), 1110 (POP3)
- Credentials stored in IRIS: `do ##class(Ens.Config.Credentials).SetCredential("mailpit", "iris", "test123")`
- AWS credentials: `AWS_BEARER_TOKEN_BEDROCK` env var, wrapped into a `%Wallet` secret and referenced from `%ConfigStore.Configuration` (see `Utils.ConfigStore`)

## Instruqt workshop (`instruqt/ai-hub-workshop/`)

Initial draft scripts/content for an Instruqt hands-on lab track built on this demo: `track.yml`, `config.yml`, and assignment steps `01-create-an-agent` through `05-extension`. Steps 01-03 have been reconciled against the current `EmailAI.*` classes. `04-adding-to-interop` and `05-extension` are still placeholder/stub content.

Note: the Instruqt assignment `.md` files still reference the old `Warehouse.*` class names and need updating to match the new names.

## Current state / known gaps

- `SupportTarget` routing exists in the Router but no BO has been created for it.
- `04-adding-to-interop` and `05-extension` Instruqt steps are still stubs with no real content.
- Instruqt assignment `.md` files reference old `Warehouse.AI.*` / `Warehouse.Interop.*` / `Warehouse.Utils.*` class names — these need updating.
