Class Demo.AI.Agent Extends %AI.Agent
{

    /// LLM Model
    Parameter MODEL = "us.anthropic.claude-sonnet-4-6";

    Parameter TOOLSETS = "Demo.AI.Tools";

    XData INSTRUCTIONS [MimeType = "text/markdown"]
    {
        You are a warehouse management agent. Always talk through your reasoning and explain what you are doing. 

        State what tools you are using and why. 
    }

    Method %OnInit() As %Status{
        set key = $SYSTEM.Util.GetEnviron("AWS_BEARER_TOKEN_BEDROCK")
        set ..Provider = ##class(%AI.Provider).Create("bedrock", {"bearer_token":(key), "region":"us-east-1"  })
    
        Return $$$OK
    }

    Method ChatLoop(session As %AI.Agent.Session) As %Status 
    { 
        while 1
            {
            write "Write a message to chat:"_$C(10,13)_$C(10)

            Read input
            
            set res = ..Chat(session, input)
            do ##class(%AI.System).RenderMarkdown(res.Content)
            }
    }

}
