interface Env {
  COMMANDCODE_API_KEY: string
}

const PROVIDER_API = "https://api.commandcode.ai/provider/v1"

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url)

    if (url.pathname === "/health") {
      return Response.json({ ok: true })
    }

    if (url.pathname === "/chat/completions" && request.method === "POST") {
      const headers = new Headers(request.headers)
      headers.set("Authorization", `Bearer ${env.COMMANDCODE_API_KEY}`)
      return fetch(`${PROVIDER_API}/chat/completions`, {
        method: "POST",
        headers,
        body: request.body,
      })
    }

    return new Response("not found", { status: 404 })
  },
}
