# Project Overview - From Fed to Chain

## Purpose

From Fed to Chain is a simplified content review system for Chinese explainers about crypto/macro economics. The project focuses on human review workflow and content management, consisting of:

1. **Node.js CLI Pipeline** - Content management, translation, TTS, and social hooks
2. **Flutter Mobile/Web App** - Modern audio streaming app for content consumption

## Core Architecture

The system operates on a content pipeline workflow:

- **Content Creation**: Manual creation of source content in Traditional Chinese (`zh-TW`)
- **Review Process**: Interactive CLI for content approval/rejection with feedback
- **Pipeline Processing**: Automated translation → audio generation → social hooks
- **Audio Streaming**: Flutter app provides modern UI for M3U8 audio streaming

## Key Features

- Multi-language support (zh-TW source, en-US, ja-JP translations)
- Content categories: daily-news, ethereum, macro, startup, ai, defi
- Audio generation via Google Cloud TTS
- M3U8 streaming format for Flutter app consumption
- Cloudflare R2 for file storage and CDN
- Interactive review workflow with feedback collection

## Business Model

Focus on content quality assurance through human review workflow, with emphasis on:

- Simplified content management
- Quality control through reviewer feedback
- Modern audio streaming experience
- Multi-platform content distribution
