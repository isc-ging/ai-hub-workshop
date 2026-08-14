---
slug: adding-to-interop
id: jxhzupzads03
type: challenge
title: Adding to Production
tabs:
- id: 033jupmvdzps
  title: Code
  type: service
  hostname: ai-hub-eap
  path: ?folder=/home/irisowner/ai-hub-workshop/src
  port: 8888
- id: pwsbjfv1qqgk
  title: IRIS
  type: terminal
  hostname: ai-hub-eap
  cmd: su - irisowner -s /usr/irissys/bin/iris session iris
- id: var1p5dmvqli
  title: IRIS
  type: service
  hostname: ai-hub-eap
  path: /csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=USER
  port: 52773
difficulty: ""
enhanced_loading: null
---

We have a working production polling a mailbox.

- Edit Business Operation to send the contents of the message to the agent
- Return the response to the BP




We have a bunch of draft emails. For each draft, send the email to the mailbox. see the agent in action.

The agent will read the email - route the message back to BP which will either go to HumanReview, or Order confirmation operations.






