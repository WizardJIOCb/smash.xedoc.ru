"""Read-only probe of the project editor through its authenticated MCP bridge."""
import asyncio
import json
import os
from pathlib import Path
import shutil
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parameters = StdioServerParameters(
        command=shutil.which("uvx"),
        args=["--from", "godot-ai==4.4.1", "godot-ai", "attach", "--port", "8000",
              "--ws-port", "9500", "--disable-telemetry"],
        env={**os.environ, "GODOT_AI_DISABLE_TELEMETRY": "true"},
    )
    async with stdio_client(parameters) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.list_tools()
            tools = [tool.model_dump(by_alias=True) for tool in result.tools]
            (root / ".tools/mcp-tools.json").write_text(json.dumps(tools, indent=2), encoding="utf-8")
            print("MCP connected; tools:", len(tools))
            if len(sys.argv) > 1:
                tool_name = sys.argv[1]
                if tool_name not in {"scene_get_hierarchy", "session_manage", "editor_screenshot"}:
                    raise ValueError("Probe only permits named read-only tools")
                arguments = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
                result = await session.call_tool(tool_name, arguments)
                serial = result.model_dump(mode="json")
                (root / ".tools/mcp-probe-result.json").write_text(
                    json.dumps(serial, ensure_ascii=False, indent=2), encoding="utf-8")
                print("Tool call:", tool_name, "isError:", getattr(result, "is_error", getattr(result, "isError", None)))
                for content in result.content:
                    if getattr(content, "type", None) == "text":
                        print(content.text[:1800])
            else:
                for tool in tools:
                    if any(word in tool["name"] for word in ("scene", "session", "status")):
                        print(tool["name"], json.dumps(tool["inputSchema"])[:1800])


asyncio.run(main())
