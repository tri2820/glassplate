interface Env {
  COMMANDCODE_API_KEY: string
  CHAT_MODEL: string
}

const PROVIDER_API = "https://api.commandcode.ai/provider/v1"

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url)

    if (url.pathname === "/health") {
      return Response.json({ ok: true })
    }

    if (url.pathname === "/chat/completions" && request.method === "POST") {
      const payload = (await request.json()) as Record<string, unknown>
      // The model is owned by the server; ignore whatever the client sent.
      payload.model = env.CHAT_MODEL

      const headers = new Headers(request.headers)
      headers.set("Authorization", `Bearer ${env.COMMANDCODE_API_KEY}`)
      headers.set("Content-Type", "application/json")
      headers.delete("Content-Length")

      return fetch(`${PROVIDER_API}/chat/completions`, {
        method: "POST",
        headers,
        body: JSON.stringify(payload),
      })
    }

    return new Response("not found", { status: 404 })
  },
}
