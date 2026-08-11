/* Copyright (c) 2026 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%AI, %occInclude)

/// Base abstraction for a Tool Provider.
/// Automatically exposes public methods as tools via introspection.
Class %AI.Tool Extends %RegisteredObject [ Abstract, DependsOn = (%AI.Tool.Schema, %AI.Tool.Generator, %Library.Global), System = 4 ]
{

/// Limit tool discovery to methods defined at or below this class in the hierarchy.
/// Unset (the default), only methods that originate in the concrete class itself are
/// exposed -- inherited methods are never exposed as tools unless you opt in. Set this
/// to an ancestor class to widen discovery to that ancestor's own methods too, e.g. a
/// class extending %AI.MCP.Service that deliberately wants to expose some of its
/// inherited infrastructure methods as tools.
Parameter DISCOVERYLIMIT As STRING;

/// If 1, ALL tools exposed by this class require explicit authorization policy approval
/// before execution. Set to 1 for any tool class that performs destructive or mutating
/// operations (file writes, deletions, database changes, shell commands, etc.).
Parameter REQUIRESAUTH As BOOLEAN = 0;

/// If 1, ALL tools exposed by this class are stateful and require a persistent
/// WebSocket connection for execution. When 0 (the default), statefulness is
/// inferred automatically: ClassMethods are stateless, instance Methods are stateful.
/// Set to 1 explicitly when ClassMethods access shared mutable state (globals, etc.).
Parameter STATEFUL As BOOLEAN = 0;

/// Maximum number of rows returned by any query tool on this class.
/// The result envelope always includes row_count, truncated, and elapsed_ms.
Parameter QUERYMAXROWS As INTEGER = 100;

/// Return the %DynamicObject mode string for a given clientdatatype and direction.
/// 
/// direction = "out" (default): IRIS value -> JSON  (use with %Set / %Push)
/// direction = "in":            JSON value -> IRIS  (use with %Get)
/// 
/// "in" modes: only stream, stream<base64, string<base64 are valid for %Get.
///             boolean/integer/number are handled natively by %Get with no mode.
ClassMethod %TypeMode(clientType As %String, direction As %String = "out") As %String [ Internal, Private ]
{
    Return $CASE(direction,
        "in": $CASE(clientType,
                  $$$cCLASSCLIENTDATATYPECHARACTERSTREAM: "stream",
                  $$$cCLASSCLIENTDATATYPEBINARYSTREAM:    "stream<base64",
                  $$$cCLASSCLIENTDATATYPEBINARY:          "string<base64",
                  :                                        ""),
        :     $CASE(clientType,
                  $$$cCLASSCLIENTDATATYPECHARACTERSTREAM: "stream",
                  $$$cCLASSCLIENTDATATYPEBINARYSTREAM:    "stream>base64",
                  $$$cCLASSCLIENTDATATYPEBOOLEAN:         "boolean",
                  $$$cCLASSCLIENTDATATYPEINTEGER:         "integer",
                  $$$cCLASSCLIENTDATATYPEBIGINT:          "integer",
                  $$$cCLASSCLIENTDATATYPEDOUBLE:          "number",
                  $$$cCLASSCLIENTDATATYPENUMERIC:         "number",
                  $$$cCLASSCLIENTDATATYPECURRENCY:        "number",
                  $$$cCLASSCLIENTDATATYPEDECIMAL:         "number",
                  $$$cCLASSCLIENTDATATYPEBINARY:          "string>base64",
                  :                                        ""))
}

/// Populate a concrete IRIS object from a %DynamicObject by walking class metadata.
/// Returns accumulated %Status; multiple property errors are collected via $$$ADDSC.
/// Modeled on HS.API.Utils:ConvertProxyObjectToConcreteObject, updated for %DynamicObject.
ClassMethod %ToObject(source As %DynamicObject, target As %RegisteredObject, useadaptor As %Boolean = 1) As %Status
{
    If '$ISOBJECT(target) {
        Return $$$ERROR($$$AICoreToolArgImportFailed, "object", "target")
    }
    If '$ISOBJECT(source) {
        Return $$$ERROR($$$AICoreToolArgImportFailed, $CLASSNAME(target), "source")
    }

    If useadaptor && target.%Extends("%JSON.Adaptor") {
        // Import using the %JSON.Adaptor
        Return target.%JSONImport(source)
    }

    Set className = $CLASSNAME(target)

    Set sc = $$$OK
    Set prop = ""
    For {
        Set prop = $$$comMemberNext(className, $$$cCLASSproperty, prop)
        Quit:prop=""

        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPprivate) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPinternal) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPmultidimensional) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPcalculated) Continue
        If $EXTRACT(prop, 1, 2) = "%%" Continue

        Set fieldName = prop

        // Use %JSON* hints if found
        Set inc = $ZCVT($$$comMemberArrayGet(className, $$$cCLASSproperty, prop, $$$cPROPparameter, "%JSONINCLUDE"), "L")
        If (inc = "none") || (inc = "outputonly") Continue
        Set jfn = $$$comMemberArrayGet(className, $$$cCLASSproperty, prop, $$$cPROPparameter, "%JSONFIELDNAME")
        If jfn '= "" Set fieldName = jfn

        Set propType   = $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPtype)
        Set collection = $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPcollection)
        Set clsType    = $$$getClassType(propType)
        Set isRequired = $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPrequired)
        Set clientType = $CASE(clsType,   $$$cCLASSCLASSTYPEDATATYPE:$$$defClassKeyGet(propType,$$$cCLASSclientdatatype),
			                            $$$cCLASSCLASSTYPEPERSISTENT:"OBJECT",
			                                $$$cCLASSCLASSTYPESERIAL:"OBJECT",
			                                $$$cCLASSCLASSTYPESTREAM:"STREAM",
			                                                        :"")
        Set mode       = ..%TypeMode(clientType, "in")

        If isRequired && (source.%GetTypeOf(fieldName) = "unassigned") {
            // Required property is missing
            Set sc = $$$ADDSC(sc, $$$ERROR($$$AICoreToolArgPropertyRequired, prop))
            Continue
        }

        Try {
            // Now, process this property
            If (collection = $$$cPROPCOLLECTIONNONE) {
                // --- Scalar / single value ---
                If clsType = $$$cCLASSCLASSTYPEDATATYPE {
                    // mode handles binary base64-decode; blank for boolean/integer/number (IRIS native)
                    Set $PROPERTY(target, prop) = source.%Get(fieldName,, mode)
                } ElseIf clsType = $$$cCLASSCLASSTYPESTREAM {
                    // mode is "stream<base64" for binary streams, "stream" for character
                    Set tStream = source.%Get(fieldName,, mode)
                    Set tProp = $PROPERTY(target, prop)
                    Do tProp.CopyFrom(tStream)
                } Else {
                    // Object type -- recurse
                    Set dynVal = source.%Get(fieldName)
                    If '$ISOBJECT(dynVal) && (dynVal'="") {
                        // non-object scalar is an error
                        Set sc = $$$ADDSC(sc, $$$ERROR($$$AICoreToolArgImportFailed, propType, prop))
                        Continue
                    }

                    Set nested = $CLASSMETHOD(propType, "%New")
                    If '$ISOBJECT(nested) {
                        Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgImportFailed, propType, prop), $GET(%objlasterror)))
                        Continue
                    }

                    Set innerSC = ..%ToObject(dynVal, nested)
                    If $$$ISERR(innerSC) {
                        Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgImportFailed, propType, prop), innerSC))
                        Continue
                    }

                    Set $PROPERTY(target, prop) = nested
                }

            } ElseIf collection = $$$cPROPCOLLECTIONLIST {
                // --- list of T ---
                Set dynArr = source.%Get(fieldName)
                If '$ISOBJECT(dynArr) || 'dynArr.%IsA("%Library.DynamicArray") {
                    Set sc = $$$ADDSC(sc, $$$ERROR($$$AICoreToolArgImportFailed, "[" _ propType _ "]", prop))
                    Continue
                }
                Set coll = $PROPERTY(target, prop)
                For idx=0:1:dynArr.%Size()-1 {
                    If clsType = $$$cCLASSCLASSTYPEDATATYPE {
                        // Scalar element
                        Set elem = dynArr.%Get(idx)
                        Do coll.Insert(elem)
                    } ElseIf clsType = $$$cCLASSCLASSTYPESTREAM {
                        // This is a stream; if it's binary then base64 decode it
                        Set tStream = dynArr.%Get(idx,, mode)
                        
                        // We need to create a stream instance to copy to
                        Set elem = $CLASSMETHOD(propType,"%New")
                        Do elem.CopyFrom(tStream)
                        Do coll.Insert(elem)
                    } Else {
                        // ListOfObjects
                        Set elem = dynArr.%Get(idx)
                        If '$ISOBJECT(elem) {
                            Set sc = $$$ADDSC(sc, $$$ERROR($$$AICoreToolArgImportFailed, propType, prop _ "[" _ idx _ "]"))
                            Continue
                        }
                        // We now need to do a nested import
                        Set nested = $CLASSMETHOD(propType, "%New")
                        If '$ISOBJECT(nested) {
                            Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgImportFailed, propType, prop _ "[" _ idx _ "]"), $GET(%objlasterror)))
                            Continue
                        }
                        Set innerSC = ..%ToObject(elem, nested)
                        If $$$ISERR(innerSC) {
                            Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgImportFailed, propType, prop _ "[" _ idx _ "]"), innerSC))
                            Continue
                        }
                        Do coll.Insert(nested)
                    }
                }

            } ElseIf collection = $$$cPROPCOLLECTIONARRAY {
                // --- array of T (string-keyed map) ---
                Set dynObj = source.%Get(fieldName)
                If '$ISOBJECT(dynObj) || 'dynObj.%IsA("%Library.DynamicObject") {
                    Set sc = $$$ADDSC(sc, $$$ERROR($$$AICoreToolArgImportFailed, "{" _ propType _ "}", prop))
                    Continue
                }
                Set coll = $PROPERTY(target, prop)
                Set iter = dynObj.%GetIterator()
                While iter.%GetNext(.k, .elem) {
                    If clsType = $$$cCLASSCLASSTYPEDATATYPE {
                        Do coll.SetAt(elem, k)
                    } ElseIf clsType = $$$cCLASSCLASSTYPESTREAM {
                        // This is a stream; if it's binary then base64 decode it.  We must re-get it though
                        Set tStream = dynObj.%Get(k,, mode)
                        
                        // We need to create a stream instance to copy to
                        Set elem = $CLASSMETHOD(propType,"%New")
                        Do elem.CopyFrom(tStream)
                        Do coll.SetAt(elem, k)
                    } Else {
                        If '$ISOBJECT(elem) {
                            Set sc = $$$ADDSC(sc, $$$ERROR($$$AICoreToolArgImportFailed, propType, prop _ "{" _ k _ "}"))
                            Continue
                        }
                        Set nested = $CLASSMETHOD(propType, "%New")
                        If '$ISOBJECT(nested) {
                            Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgImportFailed, propType, prop _ "{" _ k _ "}"), $GET(%objlasterror)))
                            Continue
                        }
                        Set innerSC = ..%ToObject(elem, nested)
                        If $$$ISERR(innerSC) {
                            Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgImportFailed, propType, prop _ "{" _ k _ "}"), innerSC))
                            Continue
                        }
                        Do coll.SetAt(nested, k)
                    }
                }
            }
        } Catch ex {
            Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgSetFailed, prop), ex.AsStatus()))
        }
    }

    Return sc
}

/// Convert a concrete IRIS object to a %DynamicObject.
/// For %JSON.Adaptor classes uses the native export pipeline (no string size limit).
/// For generic registered/serial/persistent classes walks property metadata.
ClassMethod %FromObject(source As %RegisteredObject, useadaptor As %Boolean = 1) As %DynamicObject
{
    If '$ISOBJECT(source) Return {}

    // %JSON.Adaptor: export via stream to avoid the 3.6 MB string ceiling
    If useadaptor && source.%Extends("%JSON.Adaptor") {
        Set stream = ##class(%Stream.TmpCharacter).%New()
        $$$ThrowOnError(source.%JSONExportToStream(stream))
        Return ##class(%DynamicObject).%FromJSON(stream)
    }

    // Generic class -- walk compiled property metadata
    Set className = $CLASSNAME(source)
    Set result = {}

    Set sc = $$$OK
    Set prop = ""
    For {
        Set prop = $$$comMemberNext(className, $$$cCLASSproperty, prop)
        Quit:prop=""

        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPprivate) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPinternal) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPmultidimensional) Continue
        If $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPcalculated) Continue
        If $EXTRACT(prop, 1, 2) = "%%" Continue

        Set propType   = $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPtype)
        Set collection = $$$comMemberKeyGet(className, $$$cCLASSproperty, prop, $$$cPROPcollection)
        Set clsType    = $$$getClassType(propType)
        Set clientType = $CASE(clsType,   $$$cCLASSCLASSTYPEDATATYPE:$$$defClassKeyGet(propType,$$$cCLASSclientdatatype),
			                            $$$cCLASSCLASSTYPEPERSISTENT:"OBJECT",
			                                $$$cCLASSCLASSTYPESERIAL:"OBJECT",
			                                $$$cCLASSCLASSTYPESTREAM:"STREAM",
			                                                        :"")
        Set mode       = ..%TypeMode(clientType)


        Try {
            If (collection = $$$cPROPCOLLECTIONNONE) {
                Set value = $PROPERTY(source, prop)
                If clsType = $$$cCLASSCLASSTYPEDATATYPE {
                    // mode encodes boolean/integer/numeric/binary correctly per clientType
                    Do result.%Set(prop, value, mode)
                } ElseIf clsType = $$$cCLASSCLASSTYPESTREAM {
                    // mode is "stream" for character or "stream>base64" for binary
                    Do result.%Set(prop, value, mode)
                } Else {
                    // It's an object
                    Do result.%Set(prop, ..%FromObject(value))
                }

            } ElseIf collection = $$$cPROPCOLLECTIONLIST {
                Set coll = $PROPERTY(source, prop)
                Set arr = []
                For idx=1:1:coll.Count() {
                    Set elem = coll.GetAt(idx)
                    If clsType = $$$cCLASSCLASSTYPEDATATYPE {
                        // mode encodes boolean/integer/numeric/binary correctly per clientType
                        Do arr.%Push(elem, mode)
                    } ElseIf clsType = $$$cCLASSCLASSTYPESTREAM {
                        // mode is "stream" for character or "stream>base64" for binary
                        Do arr.%Push(elem, mode)
                    } Else {
                        // It's an object
                        Do arr.%Push(..%FromObject(elem))
                    }
                }
                Do result.%Set(prop, arr)

            } ElseIf collection = $$$cPROPCOLLECTIONARRAY {
                Set coll = $PROPERTY(source, prop)
                Set obj = {}
                Set k = coll.Next("")
                While k '= "" {
                    Set elem = coll.GetAt(k)


                    If clsType = $$$cCLASSCLASSTYPEDATATYPE {
                        // This is a scalar value; mode encodes boolean/integer/binary etc.
                        Do obj.%Set(k, elem, mode)
                    } ElseIf clsType = $$$cCLASSCLASSTYPESTREAM {
                        // This is a stream, if it's binary then base64 encode it
                        Do obj.%Set(k, elem, mode)
                    } Else {
                        // It's an object
                        Do obj.%Set(k, ..%FromObject(elem))
                    }

                    Set k = coll.Next(k)
                }
                Do result.%Set(prop, obj)
            }
        } Catch ex {
            Set sc = $$$ADDSC(sc, $$$EMBEDSC($$$ERROR($$$AICoreToolArgSetFailed, prop), ex.AsStatus()))
        }
    }

    $$$ThrowOnError(sc)


    Return result
}

/// Throw a pre-built %Status as an exception.
/// Called from the $CASE default arm in the generated %Invoke body
/// because THROW is a command and cannot appear in an expression context.
Method %ToolError(sc As %Status) As %Any [ Internal ]
{
    $$$ThrowStatus(sc)
}

/// Decode an inbound tool argument into a typed IRIS object.
/// Called inline from generated %Invoke $CASE arms for complex (Tier 2/3) parameters.
/// Override this method to customise how arguments are decoded for specific tools.
/// 
/// Parameters:
///   toolname - Name of the tool being invoked (available for dispatch in overrides)
///   argname  - Name of the argument being decoded
///   cls      - Fully-qualified class name to instantiate
///   input    - Raw JSON value from the LLM (typically a %DynamicObject)
Method %Decode(toolname As %String, argname As %String, cls As %String, input As %Any) As %Any
{
    Set obj = $CLASSMETHOD(cls, "%New")
    If '$ISOBJECT(obj) $$$ThrowStatus($GET(%objlasterror, $$$ERROR($$$FailedToNewClass, cls)))
    $$$ThrowOnError(##class(%AI.Tool).%ToObject(input, obj))
    Return obj
}

/// Encode a tool return value for delivery to the caller.
/// Called from generated %Invoke after the $CASE dispatch.
/// Override this method to customise how return values are serialised for specific tools.
/// 
/// Parameters:
///   toolname - Name of the tool that was invoked
///   rv       - Raw return value from the tool method
Method %Encode(toolname As %String, rv As %Any) As %Any
{
    // Void method (no declared return type): return an empty object rather than
    // the empty string that ObjectScript yields when a void method is called in
    // an expression context.  This gives callers {} instead of "" so the result
    // is unambiguously "nothing" rather than "empty string".
    Set retType = $$$comMemberKeyGet($CLASSNAME(), $$$cCLASSmethod, toolname, $$$cMETHreturntype)
    If retType = "" Return {}  // void tool - return empty object so callers receive {}

    If $ISOBJECT(rv) {
        If rv.%IsA("%Library.DynamicAbstractObject") { Return rv }
        Return ##class(%AI.Tool).%FromObject(rv)
    }
    // %Binary returns: encode raw bytes to a base64 string for safe JSON transport.
    // RouteToolRequest's "string" setType then stores it correctly as-is.
    // (retType is guaranteed non-empty here - void methods returned {} above.)
    Set clientType = $$$defClassKeyGet(retType, $$$cCLASSclientdatatype)
    If clientType = $$$cCLASSCLIENTDATATYPEBINARY {
        Set tmp = {}
        Do tmp.%Set("v", rv, "string>base64")
        Return tmp.%Get("v")
    }
    Return rv
}

/// Discover available tools.
/// Returns a DynamicObject { "tools": [...ToolSpecs...] }.
Method %Discover() As %DynamicObject [ CodeMode = objectgenerator ]
{
    // Base class terminal -- method must exist so ##super() chains don't fail.
    If %class.Name = "%AI.Tool" {
        Do %code.WriteLine("    Return {""tools"": [], ""mcp"": []}")
        Return $$$OK
    }

    Return ##class(%AI.Tool.Generator).GenerateDiscover(
        %class.Name,
        $GET(%parameter("DISCOVERYLIMIT"), ""),
        ($GET(%parameter("REQUIRESAUTH"), 0) = 1),
        ($GET(%parameter("STATEFUL"), 0) = 1),
        %code)
}

Method %Invoke(toolname As %String, args As %DynamicObject) As %Any [ CodeMode = objectgenerator ]
{
    // Base class terminal -- method must exist so ##super() chains don't fail.
    If %class.Name = "%AI.Tool" {
        Do %code.WriteLine("    Return $$$NULLOREF")
        Return $$$OK
    }

    Return ##class(%AI.Tool.Generator).GenerateInvoke(
        %class.Name,
        $GET(%parameter("DISCOVERYLIMIT"), ""),
        %code)
}

}
