import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3"
import { getSignedUrl } from "@aws-sdk/s3-request-presigner"

function withCors(resp) {
  const headers = new Headers(resp.headers)
  headers.set("Access-Control-Allow-Origin", "*")
  headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, HEAD")
  headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept, Origin, X-Requested-With")
  headers.set("Access-Control-Allow-Credentials", "false")
  headers.set("Access-Control-Max-Age", "86400")
  headers.set("Access-Control-Expose-Headers", "Content-Length, Content-Range")
  return new Response(resp.body, {
    status: resp.status,
    headers
  })
}

export default {
  async fetch(req, env) {
    const url = new URL(req.url)

    // 👇 Handle CORS preflight
    if (req.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS, HEAD",
          "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
          "Access-Control-Allow-Credentials": "false",
          "Access-Control-Max-Age": "86400",
          "Access-Control-Expose-Headers": "Content-Length, Content-Range",
        },
      })
    }

    try {
      const path = url.searchParams.get("path")
      const listPrefix = url.searchParams.get("prefix")

      // 1️⃣ Signed playback URL
      if (path) {
        const s3 = new S3Client({
          region: "auto",
          endpoint: `https://${env.CF_R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
          credentials: {
            accessKeyId: env.R2_ACCESS_KEY_ID,
            secretAccessKey: env.R2_SECRET_ACCESS_KEY,
          },
        })

        const cmd = new GetObjectCommand({
          Bucket: "fromfedtochain",
          Key: path,
        })

        const signed = await getSignedUrl(s3, cmd, { expiresIn: 3600 })

        return withCors(Response.json({ url: signed }))
      }

      // 2️⃣ List episodes
      if (listPrefix) {
        const list = await env.R2_BUCKET.list({
          prefix: listPrefix,
          delimiter: "/",
        })

        const result = list.delimitedPrefixes.map((p) => {
          const id = p.replace(listPrefix, "").replace(/\/$/, "")
          return {
            id,
            path: `${listPrefix}${id}/playlist.m3u8`,
            signedUrl: `${url.origin}/?path=${encodeURIComponent(`${listPrefix}${id}/playlist.m3u8`)}`,
          }
        })

        return withCors(Response.json(result))
      }

      return withCors(new Response("Missing ?path= or ?prefix=", { status: 400 }))
    } catch (err) {
      console.error("Worker Error:", err)
      return withCors(new Response("Internal error", { status: 500 }))
    }
  }
}