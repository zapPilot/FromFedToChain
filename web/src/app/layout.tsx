import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/Sidebar";
import Footer from "@/components/Footer";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "From Fed to Chain - Financial Intelligence",
  description:
    "Premium audio intelligence on crypto, macro economics, and blockchain technology.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased min-h-screen bg-black text-white selection:bg-indigo-500/30`}
      >
        <div className="flex min-h-screen">
          {/* Left Sidebar (Desktop) */}
          <Sidebar />

          {/* Main Content Area */}
          {/* md:ml-64 shifts content to right of fixed sidebar on desktop */}
          <main className="flex-1 md:ml-64 min-h-screen flex flex-col relative z-0">
            {/* Mobile Header (Hidden on Desktop) */}
            <div className="md:hidden flex items-center p-4 border-b border-white/5 bg-black/50 backdrop-blur-md sticky top-0 z-30">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-bold text-sm mr-3">
                F
              </div>
              <span className="font-bold text-sm">FedToChain</span>
            </div>

            {/* Content Scroll Container */}
            <div className="flex-1 w-full max-w-5xl mx-auto">{children}</div>

            <div className="md:hidden">
              <Footer />
            </div>

            {/* Right Panel Placeholder (Hidden for now, can be enabled later for 3-column) 
                To enable 3-column, we'd adjust the max-w classes above and add a fixed right panel
            */}
          </main>
        </div>
      </body>
    </html>
  );
}
