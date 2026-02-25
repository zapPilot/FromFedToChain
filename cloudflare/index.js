const JSON_CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};

function buildJsonHeaders(cacheControl) {
  if (!cacheControl) {
    return { ...JSON_CORS_HEADERS };
  }

  return {
    ...JSON_CORS_HEADERS,
    "Cache-Control": cacheControl,
  };
}

function jsonResponse(payload, { status = 200, cacheControl } = {}) {
  return Response.json(payload, {
    status,
    headers: buildJsonHeaders(cacheControl),
  });
}

function buildSearchPaths(contentId) {
  return [
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
    `content/en/defi/${contentId}.json`,
  ];
}

async function handleContentByLanguageCategoryId(pathSegments, env) {
  const lang = pathSegments[3];
  const category = pathSegments[4];
  const contentId = pathSegments[5];

  if (!lang || !category || !contentId) {
    return jsonResponse(
      {
        error: "Language, category, and content ID required",
        format: "/api/content/{lang}/{category}/{id}",
      },
      { status: 400 },
    );
  }

  try {
    const contentKey = `content/${lang}/${category}/${contentId}.json`;
    const object = await env.R2_BUCKET.get(contentKey);

    if (!object) {
      return jsonResponse({ error: "Content not found" }, { status: 404 });
    }

    const contentText = await object.text();
    const contentData = JSON.parse(contentText);
    return jsonResponse(contentData, { cacheControl: "public, max-age=3600" });
  } catch (_error) {
    return jsonResponse({ error: "Failed to fetch content" }, { status: 500 });
  }
}

async function handleContentById(pathSegments, env) {
  const contentId = pathSegments[3];

  if (!contentId) {
    return jsonResponse({ error: "Content ID required" }, { status: 400 });
  }

  const searchPaths = buildSearchPaths(contentId);
  for (const searchPath of searchPaths) {
    try {
      const object = await env.R2_BUCKET.get(searchPath);
      if (!object) {
        continue;
      }

      const contentText = await object.text();
      const contentData = JSON.parse(contentText);

      return jsonResponse(contentData, {
        cacheControl: "public, max-age=3600",
      });
    } catch (_error) {
      // Continue searching
    }
  }

  return jsonResponse({ error: "Content not found" }, { status: 404 });
}

async function handleContentApi(url, env) {
  if (!url.pathname.startsWith("/api/content/")) {
    return null;
  }

  const pathSegments = url.pathname.split("/");

  // Handle /api/content/:lang/:category/:id
  if (pathSegments.length === 6) {
    return handleContentByLanguageCategoryId(pathSegments, env);
  }

  // Handle /api/content/:id
  if (pathSegments.length === 4) {
    return handleContentById(pathSegments, env);
  }

  return null;
}

async function handleProxy(url) {
  const proxyPath = url.pathname.replace("/proxy", "");
  const r2Url = `https://pub-c0fd079339f948e68440a1f2d8b14339.r2.dev${proxyPath}`;

  const response = await fetch(r2Url);

  return new Response(response.body, {
    status: response.status,
    headers: {
      ...Object.fromEntries(response.headers),
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
}

function parseLanguageCategoryFromPrefix(prefix) {
  const prefixParts = prefix.split("/").filter((part) => part.length > 0);
  if (prefixParts.length >= 3 && prefixParts[0] === "audio") {
    return {
      language: prefixParts[1],
      category: prefixParts[2],
    };
  }

  return {
    language: null,
    category: null,
  };
}

async function handleContentListing(url, env, language, category) {
  const contentPrefix = `content/${language}/${category}/`;
  const contentList = await env.R2_BUCKET.list({
    prefix: contentPrefix,
  });

  // Process each content file and build episode data
  const results = await Promise.all(
    contentList.objects
      .filter((obj) => obj.key.endsWith(".json"))
      .map(async (obj) => {
        const episodeId = obj.key
          .replace(contentPrefix, "")
          .replace(".json", "");

        let episodeData = {
          id: episodeId,
          path: `audio/${language}/${category}/${episodeId}/playlist.m3u8`,
          playlistUrl: `${url.origin}/proxy/audio/${language}/${category}/${episodeId}/playlist.m3u8`,
          title: episodeId,
          hasContent: false,
        };

        // Fetch content metadata
        try {
          const contentObject = await env.R2_BUCKET.get(obj.key);
          if (contentObject) {
            const contentText = await contentObject.text();
            const contentData = JSON.parse(contentText);

            // Only include episodes that have streaming_urls (audio available)
            if (contentData.streaming_urls && contentData.streaming_urls.m3u8) {
              episodeData = {
                ...episodeData,
                title: contentData.title || episodeId,
                date: contentData.date,
                category: contentData.category,
                language: contentData.language,
                hasContent: true,
              };
              return episodeData;
            }
          }
        } catch (error) {
          console.error(`Failed to fetch content for ${episodeId}:`, error);
        }

        // Return null for episodes without audio (will be filtered out)
        return null;
      }),
  );

  // Filter out null entries (episodes without audio)
  const filteredResults = results.filter((result) => result !== null);

  return jsonResponse(filteredResults, {
    cacheControl: "public, max-age=1800",
  });
}

async function handleFallbackListing(url, env, prefix) {
  const list = await env.R2_BUCKET.list({
    prefix,
    delimiter: "/",
  });

  const results = list.delimitedPrefixes.map((delimitedPrefix) => {
    const episodeId = delimitedPrefix.replace(prefix, "").replace(/\/$/, "");
    return {
      id: episodeId,
      path: `${prefix}${episodeId}/playlist.m3u8`,
      playlistUrl: `${url.origin}/proxy/${prefix}${episodeId}/playlist.m3u8`,
      title: episodeId,
      hasContent: false,
    };
  });

  return jsonResponse(results, { cacheControl: "public, max-age=1800" });
}

async function handlePrefixListing(url, env, prefix) {
  // NOTE: We use content files as source of truth (not audio directories) because
  // content files are reliably synced, while audio may be in a different bucket.
  const { language, category } = parseLanguageCategoryFromPrefix(prefix);

  // If we have language and category, list content files instead of audio directories
  // This is more reliable because content files are always synced
  if (language && category) {
    return handleContentListing(url, env, language, category);
  }

  // Fallback: if no language/category, use original audio directory listing
  return handleFallbackListing(url, env, prefix);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // 1. Content API - Serve JSON content from R2
    const contentResponse = await handleContentApi(url, env);
    if (contentResponse) {
      return contentResponse;
    }

    // 2. Proxy R2 public bucket with CORS
    if (url.pathname.startsWith("/proxy")) {
      return handleProxy(url);
    }

    // 3. List available episodes under a language/category path with content metadata
    const prefix = url.searchParams.get("prefix");
    if (prefix) {
      return handlePrefixListing(url, env, prefix);
    }

    return new Response("Missing /proxy/... or ?prefix=...", { status: 400 });
  },
};
