Class Warehouse.Utils.JSON Extends %RegisteredObject
{
        /// %AI.Agent does not enforce any response schema, so instructing a model to
    /// "respond with raw JSON only" is not reliable - it may still wrap the object
    /// in markdown code fences or add leading/trailing commentary. Strip that noise
    /// down to the outermost {...} span before handing the result to %FromJSON.
    ClassMethod ExtractJSON(pContent As %String) As %DynamicObject
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

        set json =  $Extract(pContent, start, finish)
        set object = {}.%FromJSON(json)
        return object
    }
}
