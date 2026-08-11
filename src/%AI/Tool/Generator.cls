/* Copyright (c) 2026 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%AI, %occInclude)

/// Code-generation helpers shared by the %AI.Tool and %AI.ToolSet objectgenerators.
/// 
/// When a ToolSet subclass has no Definition XData it falls back to plain
/// %AI.Tool-style discovery and dispatch.  Extracting the logic here lets
/// both generators delegate without duplicating code.
Class %AI.Tool.Generator [ System = 3 ]
{

/// Generate a %Discover method body that scans className's class dictionary
/// for public, non-%, non-Internal class methods and queries.
/// 
/// Parameters come from the calling objectgenerator's %parameter("...") reads.
ClassMethod GenerateDiscover(className As %String, discoveryLimit As %String = "", requiresAuth As %Boolean = 0, statefulParam As %Boolean = 0, code) As %Status [ Internal ]
{
    // An unset DISCOVERYLIMIT restricts discovery to methods/queries that
    // originate in className itself -- inherited members are excluded by
    // default. Set DISCOVERYLIMIT explicitly to opt back in to an ancestor's
    // members (e.g. a class extending %AI.MCP.Service for infrastructure
    // but not wanting to expose it as tools).
    Set effectiveLimit = $SELECT(discoveryLimit '= "": discoveryLimit, 1: className)

    Set tools = []
    Set methodName = ""
    For {
        Set methodName = $$$comMemberNext(className, $$$cCLASSmethod, methodName)
        Quit:methodName=""

        If $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHprivate)  Continue
        If $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHinternal) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHabstract) Continue
        If $EXTRACT(methodName) = "%" Continue
        Set origin = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHorigin)
        If '$$issubclassof^%occCompile(origin, effectiveLimit) Continue

        Set desc = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHdescription)
        Set summary = desc
        Set instructions = ""
        Set firstNL = $FIND(desc, $C(10))
        If firstNL {
            Set firstLine = $EXTRACT(desc, 1, firstNL-2)
            Set remainder = $EXTRACT(desc, firstNL, *)
            If $EXTRACT(remainder, 1) = $C(10) {
                Set summary = firstLine
                Set instructions = $EXTRACT(remainder, 2, *)
            }
        }

        Set isClassMethod = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHclassmethod)
        Set t = {"name": (methodName), "description": (summary), "source": "iris", "provider": (className)}
        Do t.%Set("requires_auth", requiresAuth, "boolean")
        Do t.%Set("stateful", ($SELECT(statefulParam: 1, 1: (isClassMethod = 0))), "boolean")
        If instructions '= "" Set t.instructions = instructions
        Set p = {"type": "object", "properties": {}, "required": []}

        Kill parsedArgs
        Set formalSpec = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHformalspec)
        Set sc = $$parseFormal^%occName("Method", methodName, formalSpec, .parsedArgs)

        For i=1:1:parsedArgs {
            Set argName  = parsedArgs(i)
            Set argType  = $GET(parsedArgs(i, 2))
            Set argDesc  = ##class(%Global).Unquote($GET(parsedArgs(i, 2, "DESCRIPTION")))
            Set elemType = ##class(%Global).Unquote($GET(parsedArgs(i, 2, "ELEMENTTYPE")))
            Set normType = $SELECT(argType '= "": $$NormalizeClassname^%occName(argType), 1: "")
            Set clsType  = $SELECT(normType '= "": $$$getClassType(normType), 1: "")

            Set collKind = $$$cPROPCOLLECTIONNONE
            If clsType = $$$cCLASSCLASSTYPEDYNAMIC {
                Set collKind = $SELECT(normType = "%Library.DynamicArray": $$$cPROPCOLLECTIONLIST, 1: $$$cPROPCOLLECTIONARRAY)
            } ElseIf normType '= "" {
                If $$issubclassof^%occCompile(normType, "%Collection.AbstractList") {
                    Set collKind = $$$cPROPCOLLECTIONLIST
                } ElseIf $$issubclassof^%occCompile(normType, "%Collection.AbstractArray") {
                    Set collKind = $$$cPROPCOLLECTIONARRAY
                }
            }

            If collKind = $$$cPROPCOLLECTIONLIST {
                If elemType '= "" {
                    Set sc = ##class(%AI.Tool.Schema).%ElementSchema(elemType, .itemSchema)
                    If $$$ISERR(sc) Return sc
                } Else {
                    Set itemSchema = {"type": "string"}
                }
                Set propSchema = {"type": "array", "items": (itemSchema)}
            } ElseIf collKind = $$$cPROPCOLLECTIONARRAY {
                If elemType '= "" {
                    Set sc = ##class(%AI.Tool.Schema).%ElementSchema(elemType, .itemSchema)
                    If $$$ISERR(sc) Return sc
                    Set propSchema = {"type": "object", "additionalProperties": (itemSchema)}
                } Else {
                    Set propSchema = {"type": "object"}
                }
            } ElseIf argType '= "" {
                Set sc = ##class(%AI.Tool.Schema).%ElementSchema(argType, .propSchema)
                If $$$ISERR(sc) Return sc
            } Else {
                Set propSchema = {"type": "string"}
            }

            If argDesc '= "" Set propSchema.description = argDesc
            Do p.properties.%Set(argName, propSchema)
            If '$DATA(parsedArgs(i, 3)) Do p.required.%Push(argName)
        }

        Set t.parameters = p

        Set retType = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHreturntype)
        If retType '= "" {
            Set normRet = $$NormalizeClassname^%occName(retType)
            Set retSc = ##class(%AI.Tool.Schema).%ElementSchema(normRet, .retSchema)
            If '$$$ISERR(retSc) {
                Set originClass   = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHorigin)
                Set retTypeParams = $$$defMemberKeyGet(originClass, $$$cCLASSmethod, methodName, $$$cMETHreturntypeparams)
                If retTypeParams '= "" {
                    Kill tmpParsed
                    Set sc = $$parseFormal^%occName("Method", methodName, "x As "_retType_"("_retTypeParams_")", .tmpParsed)
                    If $$$ISERR(sc) Return sc
                    Set retDesc = ##class(%Global).Unquote($GET(tmpParsed(1, 2, "DESCRIPTION")))
                    If retDesc '= "" Set retSchema.description = retDesc
                }
                Set t.returns = retSchema
            }
        }

        Do tools.%Push(t)
    }

    // Queries
    Set queryName = ""
    For {
        Set queryName = $$$comMemberNext(className, $$$cCLASSquery, queryName)
        Quit:queryName=""

        If $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYprivate) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYinternal) Continue
        If $EXTRACT(queryName) = "%" Continue
        Set origin = $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYorigin)
        If '$$issubclassof^%occCompile(origin, effectiveLimit) Continue

        Set desc = $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYdescription)
        Set t = {"name": (queryName), "description": (desc), "source": "iris", "provider": (className)}
        Do t.%Set("requires_auth", requiresAuth, "boolean")
        Do t.%Set("stateful", 0, "boolean")
        Set t.metadata = {"origin_class": (className), "kind": "query"}

        Set p = {"type": "object", "properties": {}, "required": []}
        Set formalSpec = $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYformalspec)
        Kill parsedArgs
        Set sc = $$parseFormal^%occName("Method", queryName, formalSpec, .parsedArgs)
        For i=1:1:parsedArgs {
            Set argName = parsedArgs(i)
            Set argType = $GET(parsedArgs(i, 2))
            Set argDesc = ##class(%Global).Unquote($GET(parsedArgs(i, 2, "DESCRIPTION")))
            Set sc = ##class(%AI.Tool.Schema).%ElementSchema(argType, .propSchema)
            If $$$ISERR(sc) Set propSchema = {"type": "string"}
            If argDesc '= "" Set propSchema.description = argDesc
            Do p.properties.%Set(argName, propSchema)
            If '$DATA(parsedArgs(i, 3)) Do p.required.%Push(argName)
        }
        Set t.parameters = p
        Set t.returns = ##class(%AI.Tools.SQL).ResultSetReturnsSchema()
        Do tools.%Push(t)
    }

    Do code.Write("    Return {""tools"": ")
    Do tools.%ToJSON(code)
    Do code.WriteLine("}")
    Return $$$OK
}

/// Generate a %Invoke method body that dispatches to className's public methods
/// and queries based on toolname.
ClassMethod GenerateInvoke(className As %String, discoveryLimit As %String = "", code) As %Status [ Internal ]
{
    // Keep this in sync with GenerateDiscover's identical default -- an unset
    // DISCOVERYLIMIT restricts dispatch to methods/queries originating in
    // className itself, so a method invocation is never possible for a
    // toolname that discovery would never have advertised.
    Set effectiveLimit = $SELECT(discoveryLimit '= "": discoveryLimit, 1: className)

    Kill methods, methodOrder, queries, queryOrder
    Set methodCount = 0
    Set queryCount  = 0
    Set maxLen = 0

    Set methodName = ""
    For {
        Set methodName = $$$comMemberNext(className, $$$cCLASSmethod, methodName)
        Quit:methodName=""

        If $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHprivate)  Continue
        If $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHinternal) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHabstract) Continue
        If $EXTRACT(methodName) = "%" Continue
        Set origin = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHorigin)
        If '$$issubclassof^%occCompile(origin, effectiveLimit) Continue

        Kill parsedArgs
        Set formalSpec = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHformalspec)
        Set sc = $$parseFormal^%occName("Method", methodName, formalSpec, .parsedArgs)

        Set argCallParts = ""
        For i=1:1:parsedArgs {
            Set argName  = parsedArgs(i)
            Set argType  = $GET(parsedArgs(i, 2))
            Set normType = $SELECT(argType '= "": $$NormalizeClassname^%occName(argType), 1: "")
            Set isPassthrough = 1

            If normType '= "" {
                Set clsType = $$$getClassType(normType)
                If (clsType '= $$$cCLASSCLASSTYPEDYNAMIC) &&
                   (clsType '= $$$cCLASSCLASSTYPEDATATYPE) &&
                   (clsType '= $$$cCLASSCLASSTYPESTREAM) &&
                   '$$issubclassof^%occCompile(normType, "%Collection.AbstractList") &&
                   '$$issubclassof^%occCompile(normType, "%Collection.AbstractArray") {
                    Set isPassthrough = 0
                    Set argCallParts = argCallParts_$SELECT(argCallParts'="": ", ", 1:"")_
                        "..%Decode(toolname, """_argName_""", """_argType_""", args."_argName_")"
                }
            }

            If isPassthrough {
                If normType = "%Library.Binary" {
                    Set argCallParts = argCallParts_$SELECT(argCallParts'="": ", ", 1:"")_
                        "args.%Get("""_argName_""",,""string<base64"")"
                } Else {
                    Set argCallParts = argCallParts_$SELECT(argCallParts'="": ", ", 1:"")_"args."_argName
                }
            }
        }

        Set retType = $$$comMemberKeyGet(className, $$$cCLASSmethod, methodName, $$$cMETHreturntype)
        Set methods(methodName, "argCall") = argCallParts
        Set methods(methodName, "isVoid")  = (retType = "")
        Set methodCount = methodCount + 1
        Set methodOrder(methodCount) = methodName
        If $LENGTH(methodName) > maxLen Set maxLen = $LENGTH(methodName)
    }

    Set queryName = ""
    For {
        Set queryName = $$$comMemberNext(className, $$$cCLASSquery, queryName)
        Quit:queryName=""

        If $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYprivate) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYinternal) Continue
        If $EXTRACT(queryName) = "%" Continue
        Set origin = $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYorigin)
        If '$$issubclassof^%occCompile(origin, effectiveLimit) Continue

        Kill parsedArgs
        Set formalSpec = $$$comMemberKeyGet(className, $$$cCLASSquery, queryName, $$$cQUERYformalspec)
        Set sc = $$parseFormal^%occName("Method", queryName, formalSpec, .parsedArgs)
        Set argCall = ""
        For i=1:1:parsedArgs {
            Set argCall = argCall_$SELECT(argCall'="": ", ", 1:"")_"args."_parsedArgs(i)
        }
        Set queries(queryName, "argCall") = argCall
        Set queryCount = queryCount + 1
        Set queryOrder(queryCount) = queryName
    }

    // Section 1: Query dispatch
    Set firstQ = 1
    For qi=1:1:queryCount {
        Set qn = queryOrder(qi)
        Do code.WriteLine($SELECT(firstQ: "    If", 1: "    } ElseIf")_" toolname = """_qn_""" {")
        Do code.WriteLine("        Set t0 = $zh")
        Do code.WriteLine("        Set stmt = ##class(%SQL.Statement).%New()")
        Do code.WriteLine("        Set sc = stmt.%PrepareClassQuery("""_className_""", """_qn_""")")
        Do code.WriteLine("        If $$$ISERR(sc) $$$ThrowStatus(sc)")
        Do code.WriteLine("        Set rs = stmt.%Execute("_queries(qn, "argCall")_")")
        Do code.WriteLine("        Return ##class(%AI.Tools.SQL).FormatResultSet(rs, ..#QUERYMAXROWS, t0)")
        Set firstQ = 0
    }
    If 'firstQ Do code.WriteLine("    }")

    // Section 2a: Void method dispatch
    Set hasNonVoid = 0
    For mi=1:1:methodCount {
        Set mn = methodOrder(mi)
        If 'methods(mn, "isVoid") { Set hasNonVoid = 1  Continue }
        Do code.WriteLine("    If toolname = """_mn_""" { Do .."_mn_"("_methods(mn, "argCall")_") Return ..%Encode(toolname, """") }")
    }

    // Section 2b: Non-void $CASE dispatch
    If hasNonVoid {
        Do code.WriteLine("    Set rv = $CASE(toolname,")
        For mi=1:1:methodCount {
            Set mn = methodOrder(mi)
            If methods(mn, "isVoid") Continue
            Set pad = $JUSTIFY("", maxLen - $LENGTH(mn))
            Do code.WriteLine("        "_pad_""""_mn_""": .."_mn_"("_methods(mn, "argCall")_"),")
        }
        Set defPad = $JUSTIFY("", maxLen + 2)
        Do code.WriteLine("        "_defPad_": ..%ToolError($$$ERROR($$$AICoreToolNotFound, toolname)))")
        Do code.WriteLine("    Return ..%Encode(toolname, rv)")
    } ElseIf methodCount > 0 {
        Do code.WriteLine("    Do ..%ToolError($$$ERROR($$$AICoreToolNotFound, toolname))")
    }

    If methodCount = 0 {
        Do code.WriteLine("    $$$ThrowStatus($$$ERROR($$$AICoreToolNotFound, toolname))")
    }

    Return $$$OK
}

}
