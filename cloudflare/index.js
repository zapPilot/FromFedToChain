import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3"
import { getSignedUrl } from "@aws-sdk/s3-request-presigner"

export default {
  async fetch(req, env) {
    try {
      const url = new URL(req.url)
      const path = url.searchParams.get("path")
      const listPrefix = url.searchParams.get("prefix")

      // 1️⃣ 簽名播放網址
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

        return Response.json({ url: signed })
      }

      // 2️⃣ 列出 prefix 下有哪些子資料夾（每集一個）
      if (listPrefix) {
        const list = await env.R2_BUCKET.list({
          prefix: listPrefix,
          delimiter: "/", // 只抓下一層資料夾，不列出所有 .ts 檔
        })

        const result = list.delimitedPrefixes.map((p) => {
          const id = p.replace(listPrefix, "").replace(/\/$/, "")
          return {
            id,
            path: `${listPrefix}${id}/playlist.m3u8`,
            signedUrl: `${url.origin}/?path=${encodeURIComponent(`${listPrefix}${id}/playlist.m3u8`)}`
          }
        })

        return Response.json(result)
      }

      return new Response("Missing ?path= 或 ?prefix=", { status: 400 })
    } catch (err) {
      console.error("Worker Error:", err)
      return new Response("Internal error", { status: 500 })
    }
  }
}