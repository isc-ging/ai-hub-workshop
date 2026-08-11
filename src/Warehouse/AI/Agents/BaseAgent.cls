Class Warehouse.AI.BaseAgent Extends %AI.Agent
{

    /// LLM Model
    Parameter MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0";

    /// Initialization method. Can be used to set provider, or add stateful tools and policies. 
    /// Called by `.%Init()`
    Method %OnInit() As %Status{
        set key = $SYSTEM.Util.GetEnviron("AWS_BEARER_TOKEN_BEDROCK")
        set ..Provider = ##class(%AI.Provider).Create("bedrock", {"bearer_token":(key), "region":"us-east-1"  })

        Return $$$OK
    }

    /// %AI.Agent does not enforce any response schema, so instructing a model to
    /// "respond with raw JSON only" is not reliable - it may still wrap the object
    /// in markdown code fences or add leading/trailing commentary. Strip that noise
    /// down to the outermost {...} span before handing the result to %FromJSON.
    ClassMethod ExtractJSON(pContent As %String) As %String
    {
        set start = $Find(pContent, "{") - 1
        if start = -1 {
            return pContent
        }

        set finish = 0
        set pos = $Find(pContent, "}")
        while pos > 0 {
            set finish = pos - 1
            set pos = $Find(pContent, "}", pos)
        }

        if (finish = 0) || (finish < start) {
            return pContent
        }

        return $Extract(pContent, start, finish)
    }

}
