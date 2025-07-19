export default {
  async fetch(request, env) {
    const url = new URL(request.url)

    // ✨ 1. Content API - Serve JSON content from R2
    if (url.pathname.startsWith("/api/content/")) {
      const pathSegments = url.pathname.split('/');
      
      // Handle /api/content/:lang/:category/:id
      if (pathSegments.length === 6) {
        const lang = pathSegments[3];
        const category = pathSegments[4];
        const contentId = pathSegments[5];
        
        if (!lang || !category || !contentId) {
          return Response.json({
            error: 'Language, category, and content ID required',
            format: '/api/content/{lang}/{category}/{id}'
          }, {
            status: 400,
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Content-Type': 'application/json'
            }
          });
        }
        
        try {
          const contentKey = `content/${lang}/${category}/${contentId}.json`;
          const object = await env.R2_BUCKET.get(contentKey);
          
          if (!object) {
            return Response.json({ error: 'Content not found' }, {
              status: 404,
              headers: {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
              }
            });
          }
          
          const contentText = await object.text();
          const contentData = JSON.parse(contentText);
          
          return Response.json(contentData, {
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Content-Type': 'application/json',
              'Cache-Control': 'public, max-age=3600'
            }
          });
          
        } catch (error) {
          return Response.json({ error: 'Failed to fetch content' }, {
            status: 500,
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Content-Type': 'application/json'
            }
          });
        }
      }
      
      // Handle /api/content/:id (simplified - tries to find in common paths)
      if (pathSegments.length === 4) {
        const contentId = pathSegments[3];
        
        if (!contentId) {
          return Response.json({ error: 'Content ID required' }, {
            status: 400,
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Content-Type': 'application/json'
            }
          });
        }
        
        // Try to find content in common language/category combinations
        const searchPaths = [
          `content/zh-TW/bitcoin/${contentId}.json`,
          `content/en/bitcoin/${contentId}.json`,
          `content/zh-TW/economics/${contentId}.json`,
          `content/en/economics/${contentId}.json`,
          `content/zh-TW/daily-news/${contentId}.json`,
          `content/en/daily-news/${contentId}.json`,
          `content/zh-TW/ethereum/${contentId}.json`,
          `content/en/ethereum/${contentId}.json`,
          `content/zh-TW/macro/${contentId}.json`,
          `content/en/macro/${contentId}.json`,
          `content/zh-TW/startup/${contentId}.json`,
          `content/en/startup/${contentId}.json`,
          `content/zh-TW/ai/${contentId}.json`,
          `content/en/ai/${contentId}.json`,
          `content/zh-TW/defi/${contentId}.json`,
          `content/en/defi/${contentId}.json`
        ];
        
        for (const searchPath of searchPaths) {
          try {
            const object = await env.R2_BUCKET.get(searchPath);
            if (object) {
              const contentText = await object.text();
              const contentData = JSON.parse(contentText);
              
              return Response.json(contentData, {
                headers: {
                  'Access-Control-Allow-Origin': '*',
                  'Content-Type': 'application/json',
                  'Cache-Control': 'public, max-age=3600'
                }
              });
            }
          } catch (error) {
            // Continue searching
          }
        }
        
        return Response.json({ error: 'Content not found' }, {
          status: 404,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
          }
        });
      }
    }

    // ✨ 2. Proxy R2 public bucket with CORS
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

    // ✨ 3. List available episodes under a language/category path with content metadata
    const prefix = url.searchParams.get("prefix")
    if (prefix) {
      const list = await env.R2_BUCKET.list({
        prefix,
        delimiter: "/", // 只列出下一層的資料夾
      })

      // Extract language and category from prefix (e.g., "audio/en-US/daily-news/")
      const prefixParts = prefix.split('/').filter(part => part.length > 0)
      let language = null
      let category = null
      
      if (prefixParts.length >= 3 && prefixParts[0] === 'audio') {
        language = prefixParts[1]
        category = prefixParts[2]
      }

      // Process each episode and fetch content metadata
      const results = await Promise.all(
        list.delimitedPrefixes.map(async (p) => {
          const episodeId = p.replace(prefix, "").replace(/\/$/, "")
          
          let episodeData = {
            id: episodeId,
            path: `${prefix}${episodeId}/playlist.m3u8`,
            playlistUrl: `${url.origin}/proxy/${prefix}${episodeId}/playlist.m3u8`,
            title: episodeId, // Fallback to ID if content not found
            hasContent: false
          }

          // Try to fetch content metadata if we have language and category
          if (language && category) {
            try {
              const contentKey = `content/${language}/${category}/${episodeId}.json`
              const contentObject = await env.R2_BUCKET.get(contentKey)
              
              if (contentObject) {
                const contentText = await contentObject.text()
                const contentData = JSON.parse(contentText)
                
                // Enrich episode data with content metadata
                episodeData = {
                  ...episodeData,
                  title: contentData.title || episodeId,
                  date: contentData.date,
                  category: contentData.category,
                  language: contentData.language,
                  hasContent: true
                }
              }
            } catch (error) {
              // Continue with fallback data if content fetch fails
              console.error(`Failed to fetch content for ${episodeId}:`, error)
            }
          }

          return episodeData
        })
      )

      return Response.json(results, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=1800' // 30-minute cache
        }
      })
    }

    return new Response("Missing /proxy/... or ?prefix=...", { status: 400 })
  }
}