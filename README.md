# AI Hub Dev Template

This repo provides a template to kickstart development with AI Hub. 

## Contents

- **./skills** - agent skills with information on using AI hub for AI agents. Move these to a suitable location for your preferred AI coding agent. 
- **./src/Sample** - Basic sample classes for tools, toolsets, agents and MCP servers. These are installed with zpm when the container is build.  
- **./src/Python** - An example stdio MCP server defined in Python and used in the IRIS Toolsets 

## Using the template

### Download AI Hub Container

1. Download an AI Hub container from the [Early Access Program Portal](https://evaluation.intersystems.com/Eval/early-access/AIHub). The docker-containers end with `docker.tar.gz`, ensure you choose the version suitable for your operating system (arm64 for macOS).


2. Load the image with: 

    ```bash
    docker load -i /path/to/iris-community-2026.3.0AI.108.0-docker.tar.gz
    ```

    Once it's complete you should see `Loaded image: docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2026.3.0AI.108.0` (if not you can use `docker images` to find the image name). 

3. Change the Image name in the [Dockerfile](./Dockerfile) to match your version and operating system (image name printed above).


### Build Template Repo

4. Clone this repo: 

```bash
git clone https://github.com/intersystems-community/ai-hub-dev-template
cd ai-hub-dev-template
```

5. Add an OPENAI_API_KEY to a file called .env in this repo. You can see an example in .env.example. If you want to use another provider, change the Sample.Agent class in src/. If you don't want to use any agents at the moment (e.g. you want to create MCP tools to access from outside the container), create an empty .env file (`touch .env`) or remove the `env_file` tag from [docker-compose.yml](./docker-compose.yml)

6. Build the container with: 

```bash
docker-compose up -d --build 
```

## Using IRIS AI Hub Container

### Accessing IRIS 

You can find the Management Portal at http://localhost:52773/csp/sys/UtilHome.csp.

Login with: 
    - SuperUser / SYS

You can access the IRIS Terminal with:

```objectscript
docker-compose exec -it iris iris session iris
```

or the bash terminal with:

```bash
docker-compose exec -it iris bash
```

### Testing Sample agent 

There is a basic agent in src/Sample.Agent, a simple way to use it from objectscript is to run the following (note this does require an OPENAI_API_KEY to be added to .env before running th container). 

```objectscript
zn "IRISAPP"
Set agent = ##class(Sample.Agent).%New()
Set sc = agent.%Init()
write:sc'=1 $SYSTEM.Status.GetErrorText(sc), !

Set session = agent.CreateSession()

Set request = "What tools do you have?"
Set response = agent.Chat(session, request)
Do ##class(%AI.System).RenderMarkdown(response.Content)
```

You can also use the agents in streaming mode as follows: 

```objectscript
// Create Stream Renderer
Set renderer = ##class(%AI.Shell.StreamRenderer).%New()

// Request requires using both tools defined in Sample.Tools and packaged in Sample.ToolSet
Set request = "Add a person named Peter aged 16, and then get people younger than 35."

// Stream Response
Set response = agent.StreamChat(session, request , renderer, "OnChunk")

```

### Try an interactive Chat Shell

```objectscript
do ##class(%AI.System).Shell("openai", $System.Util.GetEnviron("OPENAI_API_KEY"), "gpt-5-nano", "Sample.ToolSet")
```

### Test MCP Server

The build process installs an MCP server web application at http://localhost:52773/mcp/sample. You can check this MCP server is running by going to http://localhost:52773/mcp/sample/v1/services. 

For the MCP Server to be usable, there is an additional step of starting this via a Rust binary which connects to IRIS through the web gateway protocol. The Binary is installed in `/usr/irissys/bin` (should already be in PATH).  

A sample configuration is shown in [config_html.toml](./config_http.toml), which serves a remote HTTP server on port 8080 (which is exposed by the docker-compose file). **Please note, the port for the remote HTTP server is not the same as the web server port!** 

A second sample configuration is shown for a local stdio server in [config_stdio.html](./config_stdio.toml). Note, stdio servers require the agent to be running on the same machine as the `iris-mcp-server` binary, making it trickier to use with containers, as such the full instructions to use this are not included here.

#### HTTP 

To start the transport, open a bash terminal within the container: 

```bash
docker-compose exec -it iris bash 
```

Then start the `iris-mcp-server`

```bash 
iris-mcp-server -c config.toml run 
```

You can now connect the MCP server to your MCP Client of choice (e.g. coding agents like claude code) using the address: http://localhost:8080/mcp/sample. 

An example python MCP client is shown in [test_mcp.py](./test_mcp.py), which uses Langchain's MCP adapters module. To try this, run: 

```bash
pip install langchain-mcp-adapters
python test_mcp.py
```



## More Info 

For more information on this template and AI Hub in general, see some of the following: 
- [An Introduction to AI Hub, Part 1: Agents in ObjectScript | ISC Developer Community ](https://community.intersystems.com/post/introduction-ai-hub-part-1-agents-objectscript) and [Part 2: Custom MCP Servers | ISC Developer Community](https://community.intersystems.com/post/introduction-ai-hub-part-2-custom-mcp-servers)
- [ai-hub-eap](https://github.com/intersystems-community/ai-hub-eap/tree/master) for documentation and bug reporting
- [Building AI Applications with InterSystems AI Hub | Learning Service (4 mins)](https://learning.intersystems.com/course/view.php?id=2872)

