export default {
  async fetch(request) {
    const url = new URL(request.url)
    const proxyPath = url.pathname.replace('/proxy', '')
    const r2Url = `https://pub-c0fd079339f948e68440a1f2d8b14339.r2.dev${proxyPath}`

    const response = await fetch(r2Url)

    // 加上 CORS headers
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
}