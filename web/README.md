# From Fed to Chain - Web

A Next.js web application for "From Fed to Chain" - a podcast and content platform covering crypto, macro economics, and blockchain technology.

## Overview

This is the web version of the From Fed to Chain application, built with Next.js 15, TypeScript, and Tailwind CSS. It provides a clean, SEO-friendly interface for browsing and listening to episodes.

## Features

- 📰 **Episode Listings**: Browse episodes by category (Daily News, Ethereum, Macro, Startup, AI, DeFi)
- 🎧 **Audio Player**: Built-in web audio player for streaming episodes
- 📱 **Responsive Design**: Optimized for desktop and mobile devices
- 🌙 **Dark Theme**: Modern dark theme matching the mobile app aesthetic
- 🔍 **Category Filtering**: Filter episodes by category

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Deployment**: Ready for Vercel/Cloudflare Pages

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn

### Installation

```bash
npm install
```

### Development

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build

```bash
npm run build
npm start
```

## Project Structure

```
web/
├── src/
│   ├── app/              # Next.js App Router pages
│   │   ├── page.tsx      # Home page
│   │   └── episode/      # Episode detail pages
│   ├── components/       # React components
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── EpisodeCard.tsx
│   │   ├── AudioPlayer.tsx
│   │   └── CategoryFilter.tsx
│   ├── data/            # Mock data (will be replaced with API calls)
│   │   └── mock-content.ts
│   └── types/           # TypeScript type definitions
│       └── content.ts
```

## Current Status

This is the initial version with mock data. Future updates will include:

- Integration with Cloudflare Worker API
- Real audio streaming
- Search functionality
- User authentication (if needed)
- SEO optimization

## Related Projects

- **Flutter Mobile App**: `/app` - Native mobile application
- **Cloudflare Worker**: `/cloudflare` - Backend API and content serving

## License

See parent directory for license information.
