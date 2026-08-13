# Single PrepareOrder Tool Implementation Plan

**Goal:** Replace the three-tool `CreateDraftOrder` -> `ValidateDraftOrder` -> `SubmitDraftOrder` chain in `Warehouse.AI.OrderTools` with two independently valuable tools — `PrepareOrder` (deterministic facts + hard stock gate) and `SubmitDraftOrder` (commits a decision the agent made) — so the agent has a genuine reasoning step instead of a forced sequence.

**Architecture:** `PrepareOrder` looks up the product and customer, builds the draft order in memory, and returns a JSON string of raw facts (stock sufficiency, total price vs. threshold, delivery address match, customer trust flag). It does NOT decide `ReviewRequired` — that's a judgment call the agent must make from the facts, using the same `ReviewRequired`/`ReasonForReview`/`AgentNotes` contract already documented in `CLAUDE.md`. `SubmitDraftOrder` then takes the agent's decision (`pReviewRequired`, `pReasonForReview`) and persists it. The `DraftOrder` property still carries state between the two calls in the same session, preserving the "stateful tool" teaching point — but the sequence now has exactly one decision point instead of three mechanical steps.

**Tech Stack:** ObjectScript, `%AI.Tool`, `%AI.ToolSet`, `Warehouse.Data.DraftOrder`/`Customer`/`Product`.

---

## Design decisions (context for later tasks)

- **Hard stop stays deterministic.** Insufficient stock is not a judgment call — `PrepareOrder` still refuses outright (returns an `ERROR:` string, no draft built) exactly like the old `ValidateDraftOrder` did. This mirrors the assignment's original rule ("Product low of stock, cannot continue with order") and keeps the plan's edit size small.
- **Price threshold and address mismatch move to the agent.** These are the two judgment calls in the original `ValidateDraftOrder`. `PrepareOrder` reports the raw numbers (`totalPrice`, `reviewPriceThreshold`, `deliveryAddress`, `customerDefaultAddress`, `addressMatches`, `customerTrusted`) and lets the agent apply policy from its instructions, the same way `Warehouse.AI.Agent`'s existing `OrderAgent` JSON contract (`ReviewRequired`, `ReasonForReview`, `AgentNotes`) already expects reasoning about `OutOfStock|UntrustedCustomer|NewCustomer|Other`.
- **`Validated` property is removed.** It existed only to gate the old three-step chain; with two tools there's nothing left for it to gate.
- **`LookUpCustomer` is not duplicated.** `PrepareOrder` still needs the full `Customer` object (not just the SQL-projected fields `LookUpCustomer` returns) to read `DefaultDeliveryAddress` and `Trusted`, so it opens the object directly via `%OpenId`, same as before. `LookUpCustomer` remains a separate, agent-callable tool for cases where the agent just needs to resolve an email to a customer ID before calling `PrepareOrder`.

---

## File Structure

- Modify: `src/Warehouse/AI/OrderTools.cls` — collapse to `PrepareOrder` + `SubmitDraftOrder`.
- Modify: `src/Warehouse/AI/Agent.cls` — update `INSTRUCTIONS` XData to describe the two tools and the review-decision policy.
- Modify: `instruqt/ai-hub-workshop/04-give-autonomy/assignment.md` — rewrite to teach the new two-tool design instead of the three-tool chain.
- No changes needed to: `Warehouse.Data.DraftOrder` (already has `ReviewRequired`), `Warehouse.AI.LookupTools`, `Warehouse.AI.ToolSet` (still just includes `OrderTools`, no new class added).

---

### Task 1: Rewrite `OrderTools.cls` with `PrepareOrder` and `SubmitDraftOrder`

**Files:**
- Modify: `src/Warehouse/AI/OrderTools.cls`

- [ ] **Step 1: Replace the whole class body**

```objectscript
Class Warehouse.AI.OrderTools Extends %AI.Tool
{

Property DraftOrder As Warehouse.Data.DraftOrder;

/// Threshold price above which an order requires human review
Parameter REVIEWPRICETHRESHOLD = 2000;

/// Look up the product and customer, build a draft order in memory, and return
/// the facts needed to decide whether the order requires human review.
/// This tool does NOT decide ReviewRequired - use the returned facts plus your
/// instructions to make that judgment, then call SubmitDraftOrder with your decision.
/// Insufficient stock is a hard stop: no draft is built and an ERROR is returned.
Method PrepareOrder(pProductId As %String, pQuantity As %Integer, pCustomerId As %String, pDeliveryAddress As %String = "") As %String
{
    set product = ##class(Warehouse.Data.Product).%OpenId(pProductId)
    if '$IsObject(product) quit "ERROR: Product ID not recognised"

    set customer = ##class(Warehouse.Data.Customer).%OpenId(pCustomerId)
    if '$IsObject(customer) quit "ERROR: Customer ID not recognised"

    if pQuantity > product.Quantity {
        quit "ERROR: Product low on stock, cannot continue with order. Requested "_pQuantity_", available "_product.Quantity
    }

    set resolvedAddress = pDeliveryAddress
    if (resolvedAddress = "") {
        set resolvedAddress = customer.DefaultDeliveryAddress
    }

    set ..DraftOrder = ##class(Warehouse.Data.DraftOrder).%New()
    set ..DraftOrder.Product = product
    set ..DraftOrder.Quantity = pQuantity
    set ..DraftOrder.Customer = customer
    set ..DraftOrder.DeliveryAddress = resolvedAddress

    set totalPrice = pQuantity * product.UnitPrice
    set addressMatches = (resolvedAddress = customer.DefaultDeliveryAddress)

    set facts = {}
    set facts.sufficientStock = 1
    set facts.totalPrice = totalPrice
    set facts.reviewPriceThreshold = ..#REVIEWPRICETHRESHOLD
    set facts.deliveryAddress = resolvedAddress
    set facts.customerDefaultAddress = customer.DefaultDeliveryAddress
    set facts.addressMatches = addressMatches
    set facts.customerTrusted = customer.Trusted
    set facts.note = "Draft order prepared but not saved. Decide ReviewRequired from these facts (e.g. totalPrice > reviewPriceThreshold, or addressMatches = false, or customerTrusted = false), then call SubmitDraftOrder with your decision and a ReasonForReview if required."

    quit facts.%ToJSON()
}

/// Commit the draft order prepared by PrepareOrder, recording the agent's review decision.
/// Must be called after PrepareOrder in the same session, or the draft is discarded.
Method SubmitDraftOrder(pReviewRequired As %Boolean, pReasonForReview As %String = "") As %String
{
    if '$IsObject(..DraftOrder) {
        quit "ERROR: No draft order to submit. Call PrepareOrder first."
    }

    set ..DraftOrder.ReviewRequired = pReviewRequired

    set st = ..DraftOrder.%Save()
    if st {
        quit ..DraftOrder.%Id()
    } else {
        quit $System.Status.GetErrorText(st)
    }
}

}
```

- [ ] **Step 2: Save the file.** The IDE recompiles ObjectScript on save — no manual compile step needed.

---

### Task 2: Update the agent's instructions to describe the two-tool decision

**Files:**
- Modify: `src/Warehouse/AI/Agent.cls:32-71` (the `INSTRUCTIONS` XData block)

- [ ] **Step 1: Add a `## Placing Orders` section to the instructions**

Insert this section into the `INSTRUCTIONS` XData, after `## Responsibilities` and before `## Restrictions`:

```markdown
## Placing Orders

When a customer request has enough information to place an order:

1. Call `PrepareOrder` with the product, quantity, customer, and delivery address (if given).
2. `PrepareOrder` returns facts about the order — it does NOT decide whether human review is required. You must decide, using these rules:
   - If `totalPrice > reviewPriceThreshold`, review is required (`ReasonForReview: "OutOfStock"` does not apply here — use `"Other"` and explain the price in `AgentNotes`).
   - If `addressMatches` is false, review is required (`ReasonForReview: "Other"`, note the address change in `AgentNotes`).
   - If `customerTrusted` is false, review is required (`ReasonForReview: "UntrustedCustomer"`).
   - Otherwise, review is not required.
3. Call `SubmitDraftOrder` with your `ReviewRequired` decision and, if true, a short reason in your own words.
4. If `PrepareOrder` returns an `ERROR:` string, do not call `SubmitDraftOrder` — report the error instead.
```

- [ ] **Step 2: Save the file.** Assume it compiles.

---

### Task 3: Rewrite the Instruqt assignment for the new design

DO NOT DO THIS. THIS IS A HUMAN JOB.


### Task 4: Manually verify the new flow via the IRIS shell

No automated test harness exists in this repo for the AI agent flow (confirmed: no `*Test*.cls` files present). Verification is manual, via the same shell commands the assignment itself uses.

**Files:** none (verification only)

- [ ] **Step 1: Run the clean, in-stock, in-policy order**

```objectscript
set email = ##class(Warehouse.Utils.Emails).ReturnEmailString(3)
set output = ##class(Warehouse.AI.Agent).ProcessEmail(email)
zw output
```

Expect (email 3 is "20 TS-400 sensors to our usual warehouse", well under the price threshold, address matches, customer C1001 is trusted): the console audit log (from `Warehouse.AI.ConsoleAudit`) shows a `PrepareOrder` call followed by a `SubmitDraftOrder` call with `pReviewRequired=0`, and `output` reflects an order placed without review.

- [ ] **Step 2: Run the over-threshold order**

```objectscript
set email = ##class(Warehouse.Utils.Emails).ReturnEmailString(4)
set output = ##class(Warehouse.AI.Agent).ProcessEmail(email)
zw output
```

Expect (email 4 is "40 TS-400 sensors", 40 * 80.00 = £3,200, over the £2,000 threshold): console log shows `SubmitDraftOrder` called with `pReviewRequired=1` and a `ReasonForReview`/`AgentNotes` mentioning the price.

- [ ] **Step 3: Run the address-change order**

```objectscript
set email = ##class(Warehouse.Utils.Emails).ReturnEmailString(5)
set output = ##class(Warehouse.AI.Agent).ProcessEmail(email)
zw output
```

Expect (email 5 explicitly overrides the delivery address): console log shows `PrepareOrder` returning `addressMatches: false`, and `SubmitDraftOrder` called with `pReviewRequired=1`.

- [ ] **Step 4: Confirm drafts landed in IRIS**

```objectscript
set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID, ReviewRequired, Quantity FROM Warehouse_Data.DraftOrder")
while rs.%Next() { w rs.%Get("ID"), " ", rs.%Get("ReviewRequired"), " ", rs.%Get("Quantity"), ! }
```

Expect three rows, with `ReviewRequired` = 0, 1, 1 matching steps 1-3.

Do not attempt to compile any `.cls` file yourself — VS Code autocompiles ObjectScript on save. If a step's expected output doesn't match, report what you observed rather than trying to recompile or re-save to "fix" it.

---

## Self-Review

**Spec coverage:**
- Single `PrepareOrder` tool replacing the create/validate split -> Task 1.
- Response requires agent reasoning (facts, not a `ReviewRequired` verdict) -> Task 1, `PrepareOrder` facts JSON + Task 2 policy instructions.
- Stock check stays a hard deterministic gate -> Task 1, Step 1.
- Stateful property lesson preserved -> `DraftOrder` property still shared across the two calls.
- `LookUpCustomer` not duplicated -> Design decisions section explains why `PrepareOrder` still opens `Customer` directly.
- Instruqt assignment updated to teach the new design -> Task 3.
- Verification without a test harness -> Task 4, manual shell steps against existing sample emails/data.

**Placeholder scan:** no TBD/TODO; all code blocks are complete; test steps have concrete expected values (computed from `PopulateDemo.cls` data: TS-400 `UnitPrice=80.00`, `Quantity=120`; C1001 trusted, `DefaultDeliveryAddress="Edinburgh Warehouse"`).

**Type consistency:** `PrepareOrder(pProductId, pQuantity, pCustomerId, pDeliveryAddress)` and `SubmitDraftOrder(pReviewRequired, pReasonForReview)` signatures match between Task 1's class body, Task 2's instructions, and Task 3's assignment rewrite.
