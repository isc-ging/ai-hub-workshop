Class Utils.ConfigStore
{
ClassMethod CreateSecretResources(pKey as %String)
{
    New $NAMESPACE
    Set $NAMESPACE="%SYS"
    DO ##class(Security.Resources).Create("ConfigStoreUse")
    DO ##class(Security.Resources).Create("ConfigStoreEdit")

    Do ##class(%Wallet.Collection).Delete("MyCollection")
    Do ##class(%Wallet.Collection).Create("MyCollection", {"UseResource" : "ConfigStoreUse", "EditResource" : "ConfigStoreEdit"})


    set secret1 = {
        "Usage": "CUSTOM",
        "Secret": {
            "key": (pKey)
        }
    }
    
    $$$QuitOnError(##class(%Wallet.KeyValue).Create("MyCollection.BedrockKey", secret1))
}

ClassMethod SaveResources(pKey As %String) As %Status
{
    Do ..CreateSecretResources(pKey)
    w "Secret resources created.", !

    Do ##class(%ConfigStore.Configuration).Delete("AI.LLM.Haiku")


    set llm1 = {
        "model_provider": "bedrock",
        "model": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
        "region":"us-east-1",
        "bearer_token": "secret://MyCollection.BedrockKey#key"
    }


    $$$QuitOnError(##class(%ConfigStore.Configuration).Create("AI", "LLM", "bedrock", "claude-haiku-4-5", llm1, "Claude Haiku 4.5", "", "ConfigStoreUser:R"))

    quit $$$OK
}

}
