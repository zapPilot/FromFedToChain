import { Episode } from "@/types/content";

export const mockEpisodes: Episode[] = [
  {
    id: "2026-01-09-bitcoin-surge",
    status: "published",
    category: "daily-news",
    date: "2026-01-09",
    language: "en-US",
    title: "Bitcoin Surges Past $50,000: Market Analysis and Future Outlook",
    description:
      "Bitcoin reaches new heights as institutional adoption continues to grow. We analyze the factors driving this surge and what it means for the crypto market.",
    content: `
      <p>Bitcoin has once again captured headlines as it surged past the $50,000 mark, reaching levels not seen in months. This significant milestone comes amid growing institutional interest and favorable regulatory developments.</p>
      
      <h2>Key Factors Driving the Surge</h2>
      <p>Several factors have contributed to Bitcoin's recent price action:</p>
      <ul>
        <li><strong>Institutional Adoption:</strong> Major corporations and financial institutions continue to add Bitcoin to their balance sheets, signaling long-term confidence in the asset.</li>
        <li><strong>Regulatory Clarity:</strong> Recent regulatory developments have provided more clarity for institutional investors, reducing uncertainty.</li>
        <li><strong>Macro Environment:</strong> Economic conditions have created a favorable backdrop for alternative assets like Bitcoin.</li>
      </ul>
      
      <h2>Market Implications</h2>
      <p>The surge in Bitcoin's price has broader implications for the cryptocurrency market. Altcoins have also seen increased activity, and trading volumes across major exchanges have spiked.</p>
      
      <p>As we look ahead, market participants are watching key resistance levels and institutional flows to gauge the sustainability of this rally.</p>
    `,
    references: [
      "CoinMarketCap Data",
      "Institutional Investment Reports",
      "Regulatory Announcements",
    ],
    streaming_urls: {
      m3u8: "https://example.com/audio/en-US/daily-news/2026-01-09-bitcoin-surge/audio.m3u8",
    },
    social_hook: "🚀 Bitcoin breaks $50K! What does this mean for the market?",
    updated_at: "2026-01-09T10:00:00Z",
  },
  {
    id: "2026-01-08-ethereum-upgrade",
    status: "published",
    category: "ethereum",
    date: "2026-01-08",
    language: "en-US",
    title: "Ethereum Network Upgrade: Enhanced Scalability and Lower Fees",
    description:
      "The latest Ethereum upgrade introduces significant improvements to transaction throughput and cost efficiency, addressing long-standing network concerns.",
    content: `
      <p>The Ethereum network has successfully implemented its latest upgrade, bringing substantial improvements to scalability and transaction costs. This upgrade represents a major milestone in Ethereum's evolution.</p>
      
      <h2>Technical Improvements</h2>
      <p>The upgrade includes several key technical enhancements:</p>
      <ul>
        <li><strong>Increased Throughput:</strong> Transaction processing capacity has been significantly increased, allowing for more transactions per second.</li>
        <li><strong>Reduced Fees:</strong> Gas fees have been optimized, making transactions more affordable for users.</li>
        <li><strong>Enhanced Security:</strong> Additional security measures have been implemented to protect the network.</li>
      </ul>
      
      <h2>Impact on Developers and Users</h2>
      <p>These improvements are particularly beneficial for DeFi applications and NFT marketplaces, which have been constrained by high gas fees. Developers can now build more cost-effective applications on Ethereum.</p>
    `,
    references: [
      "Ethereum Foundation Announcement",
      "Network Upgrade Documentation",
    ],
    streaming_urls: {
      m3u8: "https://example.com/audio/en-US/ethereum/2026-01-08-ethereum-upgrade/audio.m3u8",
    },
    social_hook: "⚡ Ethereum upgrade brings major scalability improvements!",
    updated_at: "2026-01-08T14:30:00Z",
  },
  {
    id: "2026-01-07-macro-outlook",
    status: "published",
    category: "macro",
    date: "2026-01-07",
    language: "en-US",
    title: "2026 Macro Economic Outlook: Fed Policy and Crypto Markets",
    description:
      "An in-depth analysis of how Federal Reserve policies are expected to impact cryptocurrency markets in 2026, with insights from leading economists.",
    content: `
      <p>As we move into 2026, macroeconomic factors continue to play a crucial role in cryptocurrency market dynamics. Federal Reserve policy decisions remain a key driver of market sentiment and asset prices.</p>
      
      <h2>Fed Policy Expectations</h2>
      <p>Market participants are closely watching the Federal Reserve's approach to interest rates and monetary policy. Current expectations suggest:</p>
      <ul>
        <li>Potential rate adjustments based on inflation data</li>
        <li>Continued focus on economic stability</li>
        <li>Balanced approach to monetary tightening</li>
      </ul>
      
      <h2>Crypto Market Response</h2>
      <p>Cryptocurrency markets have historically shown sensitivity to Fed policy changes. As traditional finance and crypto become more interconnected, these policy decisions have increasing relevance for digital asset investors.</p>
      
      <p>Understanding these macroeconomic trends is essential for making informed investment decisions in the crypto space.</p>
    `,
    references: [
      "Federal Reserve Statements",
      "Economic Research Reports",
      "Market Analysis Data",
    ],
    streaming_urls: {
      m3u8: "https://example.com/audio/en-US/macro/2026-01-07-macro-outlook/audio.m3u8",
    },
    social_hook: "📊 How will Fed policy impact crypto in 2026?",
    updated_at: "2026-01-07T09:15:00Z",
  },
  {
    id: "2026-01-06-defi-innovation",
    status: "published",
    category: "defi",
    date: "2026-01-06",
    language: "en-US",
    title: "DeFi Innovation: New Protocols Reshaping Decentralized Finance",
    description:
      "Exploring the latest innovations in DeFi, including new lending protocols, yield farming strategies, and cross-chain solutions.",
    content: `
      <p>The DeFi ecosystem continues to evolve rapidly, with new protocols and innovations emerging regularly. This week, we've seen several significant developments that could reshape the decentralized finance landscape.</p>
      
      <h2>Key Innovations</h2>
      <ul>
        <li><strong>Advanced Lending Protocols:</strong> New mechanisms for collateral management and interest rate optimization</li>
        <li><strong>Yield Farming Strategies:</strong> More efficient ways to maximize returns while managing risk</li>
        <li><strong>Cross-Chain Solutions:</strong> Improved interoperability between different blockchain networks</li>
      </ul>
      
      <h2>Market Impact</h2>
      <p>These innovations are attracting both retail and institutional investors, contributing to the growth of total value locked (TVL) in DeFi protocols.</p>
    `,
    references: [
      "DeFi Protocol Documentation",
      "TVL Analytics",
      "Industry Research",
    ],
    streaming_urls: {
      m3u8: "https://example.com/audio/en-US/defi/2026-01-06-defi-innovation/audio.m3u8",
    },
    social_hook: "💎 DeFi innovation continues to reshape finance!",
    updated_at: "2026-01-06T16:45:00Z",
  },
  {
    id: "2026-01-05-ai-blockchain",
    status: "published",
    category: "ai",
    date: "2026-01-05",
    language: "en-US",
    title: "AI Meets Blockchain: The Future of Smart Contracts",
    description:
      "How artificial intelligence is being integrated into blockchain technology to create more intelligent and autonomous smart contracts.",
    content: `
      <p>The intersection of artificial intelligence and blockchain technology is creating exciting new possibilities. AI-powered smart contracts are emerging as a game-changing innovation in the crypto space.</p>
      
      <h2>AI-Enhanced Smart Contracts</h2>
      <p>These next-generation smart contracts leverage AI to:</p>
      <ul>
        <li>Automatically adapt to changing conditions</li>
        <li>Optimize execution based on real-time data</li>
        <li>Provide more sophisticated decision-making capabilities</li>
      </ul>
      
      <h2>Potential Applications</h2>
      <p>From automated trading strategies to intelligent DeFi protocols, AI-blockchain integration opens up numerous possibilities for innovation.</p>
    `,
    references: [
      "AI Research Papers",
      "Blockchain Development Reports",
      "Industry Case Studies",
    ],
    streaming_urls: {
      m3u8: "https://example.com/audio/en-US/ai/2026-01-05-ai-blockchain/audio.m3u8",
    },
    social_hook: "🤖 AI and blockchain: The future of smart contracts!",
    updated_at: "2026-01-05T11:20:00Z",
  },
];

export function getEpisodeById(id: string): Episode | undefined {
  return mockEpisodes.find((episode) => episode.id === id);
}

export function getEpisodesByCategory(category?: string): Episode[] {
  if (!category) return mockEpisodes;
  return mockEpisodes.filter((episode) => episode.category === category);
}
