export default {
  async fetch(request, env) {
    const url = new URL(request.url)

    // ✨ 1. Proxy R2 public bucket with CORS
    if (url.pathname.startsWith("/proxy")) {
      const proxyPath = url.pathname.replace("/proxy", "")
      const r2Url = `https://pub-c0fd079339f948e68440a1f2d8b14339.r2.dev${proxyPath}`

      const response = await fetch(r2Url)

      return new Response(response.body, {
        status: response.status,
        headers: {
          ...Object.fromEntries(response.headers),
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET',
          'Access-Control-Allow-Headers': 'Content-Type',
        }
      })
    }

    // ✨ 2. List available episodes under a language/category path
    const prefix = url.searchParams.get("prefix")
    if (prefix) {
      const list = await env.R2_BUCKET.list({
        prefix,
        delimiter: "/", // 只列出下一層的資料夾
      })

      const results = list.delimitedPrefixes.map((p) => {
        const episodeId = p.replace(prefix, "").replace(/\/$/, "")
        return {
          id: episodeId,
          path: `${prefix}${episodeId}/playlist.m3u8`,
          playlistUrl: `${url.origin}/proxy/${prefix}${episodeId}/playlist.m3u8`,
        }
      })

      return Response.json(results, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json',
        }
      })
    }

    return new Response("Missing /proxy/... or ?prefix=...", { status: 400 })
  }
}