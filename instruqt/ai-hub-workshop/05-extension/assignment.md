---
slug: extension
id: rqysuvamy22d
type: challenge
title: Adding to Production
tabs:
- id: dbyoibi6wnqw
  title: Code
  type: service
  hostname: ai-hub-eap
  path: ?folder=/home/irisowner/ai-hub-workshop/src
  port: 8888
- id: 6qfdy4gm0yrm
  title: IRIS
  type: terminal
  hostname: ai-hub-eap
  cmd: su - irisowner -s /usr/irissys/bin/iris session iris
- id: zyxlogb3hsvv
  title: IRIS
  type: service
  hostname: ai-hub-eap
  path: /csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=USER
  port: 52773
difficulty: ""
enhanced_loading: null
---


Extension Challenge
