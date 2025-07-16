export default {
  async fetch(req, env) {
    const url = new URL(req.url)
    const path = url.searchParams.get("path")
    if (!path) return new Response("Missing ?path=", { status: 400 })

    const signed = await env.R2_BUCKET.getSignedUrl(path, {
      method: "GET",
      expiresIn: 3600, // 1 小時
    })

    return Response.json({ url: signed })
  }
}
