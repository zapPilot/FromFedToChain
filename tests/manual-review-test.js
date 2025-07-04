#!/usr/bin/env node

// Manual test script for review functionality
// Run this to test the review command interactively

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { ContentManager } from "../src/ContentManager.js";

const TEST_DIR = "./test-content";

async function setupTestContent() {
  console.log(chalk.blue("🔧 Setting up test content..."));

  // Create test directory
  await fs.mkdir(TEST_DIR, { recursive: true });

  // Temporarily change ContentManager to use test directory
  const originalDir = ContentManager.CONTENT_DIR;
  ContentManager.CONTENT_DIR = TEST_DIR;

  // Create sample content
  const testContents = [
    {
      title: "Bitcoin Institutional Adoption Surge",
      content: `你有沒有想過，當全世界最保守的錢都開始瘋狂湧入比特幣時，這意味著什麼？

最近這波比特幣突破新高，背後的驅動力已經完全不同於以往的零售投資者FOMO。這次，是機構資金的系統性配置。

讓我們從幾個數據說起：

首先，MicroStrategy再次增持，持倉超過40萬顆比特幣，價值已經接近400億美元。但更重要的是，他們的做法正在被越來越多的上市公司模仿。

其次，比特幣ETF的資金流入速度超乎想像。單週流入就超過了30億美元，這個數字是什麼概念？相當於整個台灣股市一天的交易量。

最關鍵的是政策層面的轉變。美國多個州開始立法，允許州政府將比特幣作為戰略儲備資產。這不只是投資，而是貨幣政策的根本性轉變。

那麼，為什麼這些機構突然對比特幣如此積極？

答案很簡單：通脹對沖和資產配置多元化。當傳統的60/40股債配置在高通脹環境下失效時，比特幣成為了唯一能夠真正對抗貨幣貶值的資產。

但這也帶來了新的風險。機構資金的大量湧入，意味著比特幣的價格波動將更加劇烈。當機構開始套利時，散戶投資者很可能成為最大的受害者。

所以，這波行情的邏輯已經不是"數字黃金"的故事，而是"機構避險工具"的現實。

下一個值得關注的時間點是美聯儲的下次議息會議。如果降息預期落空，機構資金很可能會重新評估比特幣的配置權重。`,
      category: "daily-news",
      references: [
        "Bloomberg Terminal",
        "CoinGecko",
        "Federal Reserve Economic Data",
      ],
    },
    {
      title: "DeFi協議治理代幣的價值重估",
      content: `最近Uniswap的治理提案引發了整個DeFi生態的討論，但真正的問題是：治理代幣到底值多少錢？

傳統的估值模型在DeFi世界完全失效。你不能用PE比、現金流折現這些方法來評估一個去中心化協議的代幣價值。

那麼，治理代幣的價值到底來自哪裡？

第一層價值：協議收入的分享權。像Uniswap這樣的AMM協議，每筆交易都會產生手續費。持有UNI代幣，理論上就有權分享這些收入。

第二層價值：治理決策的影響力。在DeFi世界，代碼就是法律，而治理投票就是修法過程。持有足夠的治理代幣，你就能影響協議的發展方向。

第三層價值：生態系統的網絡效應。當一個協議成為行業標準時，其治理代幣就會獲得類似"數字油田"的地位。

但這裡有個悖論：大部分治理代幣持有者並不真正參與治理。根據統計，平均只有5-15%的代幣持有者會參與投票。

這就創造了一個有趣的權力結構：少數活躍的大戶實際控制了協議的未來，而大部分散戶只是被動地承擔著價格波動的風險。

更複雜的是，許多DeFi協議還沒有實現真正的價值捕獲。他們產生了大量的交易量和手續費，但這些價值並沒有流向代幣持有者。

未來的趨勢是什麼？我認為會出現兩個方向：

一是"股息化"：越來越多的協議會開始向代幣持有者分配收入，就像傳統公司分紅一樣。

二是"功能化"：治理代幣會獲得更多的實用功能，比如質押挖礦、手續費折扣等等。

但無論如何，治理代幣的估值邏輯正在發生根本性變化。從純粹的投機工具，轉變為具有實際經濟價值的數字資產。

這個轉變的速度，可能比我們想像的更快。`,
      category: "ethereum",
      references: ["DefiLlama", "Snapshot.org", "Dune Analytics"],
    },
  ];

  // Create content files
  for (let i = 0; i < testContents.length; i++) {
    const content = testContents[i];
    const id = `2025-06-30-test-${i + 1}`;
    await ContentManager.create(
      id,
      content.category,
      content.title,
      content.content,
      content.references,
    );
  }

  console.log(
    chalk.green(`✅ Created ${testContents.length} test content items`),
  );
  console.log(chalk.gray(`📁 Content stored in: ${TEST_DIR}`));

  return originalDir;
}

async function cleanupTestContent(originalDir) {
  console.log(chalk.blue("\n🧹 Cleaning up test content..."));

  try {
    await fs.rm(TEST_DIR, { recursive: true, force: true });
    ContentManager.CONTENT_DIR = originalDir;
    console.log(chalk.green("✅ Test content cleaned up"));
  } catch (error) {
    console.log(chalk.yellow(`⚠️ Cleanup warning: ${error.message}`));
  }
}

async function main() {
  console.log(chalk.blue.bold("🧪 Manual Review Test"));
  console.log(chalk.gray("=".repeat(50)));
  console.log(
    chalk.yellow(
      "This will create test content and let you try the review command.",
    ),
  );
  console.log(chalk.gray("Press Ctrl+C to exit at any time.\n"));

  let originalDir;

  try {
    originalDir = await setupTestContent();

    console.log(chalk.cyan("\n📝 Test content created. Now run:"));
    console.log(chalk.white("npm run review"));
    console.log(chalk.gray("\nTry these review commands:"));
    console.log(chalk.gray("• a - Accept content"));
    console.log(chalk.gray("• a great analysis - Accept with feedback"));
    console.log(chalk.gray("• r - Reject content"));
    console.log(chalk.gray("• r needs more data - Reject with feedback"));
    console.log(chalk.gray("• s - Skip content"));
    console.log(chalk.gray("• q - Quit review session"));

    console.log(
      chalk.blue(
        "\n🔍 When done testing, run this script again with --cleanup",
      ),
    );
  } catch (error) {
    console.error(chalk.red(`❌ Setup failed: ${error.message}`));
    if (originalDir) {
      await cleanupTestContent(originalDir);
    }
    process.exit(1);
  }
}

// Check for cleanup flag
if (process.argv.includes("--cleanup")) {
  console.log(chalk.blue("🧹 Cleaning up test content..."));
  try {
    await fs.rm(TEST_DIR, { recursive: true, force: true });
    console.log(chalk.green("✅ Test content cleaned up"));
  } catch (error) {
    console.log(
      chalk.yellow(`⚠️ No test content to clean up: ${error.message}`),
    );
  }
} else {
  main();
}
