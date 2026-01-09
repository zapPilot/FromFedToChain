import Link from "next/link";

export default function Header() {
  return (
    <header className="border-b border-zinc-800 bg-black/50 backdrop-blur-sm">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <Link
            href="/"
            className="text-2xl font-bold text-white hover:text-zinc-300 transition-colors"
          >
            From Fed to Chain
          </Link>
          <nav className="hidden md:flex gap-6">
            <Link
              href="/"
              className="text-zinc-400 hover:text-white transition-colors"
            >
              Episodes
            </Link>
            <Link
              href="/about"
              className="text-zinc-400 hover:text-white transition-colors"
            >
              About
            </Link>
          </nav>
        </div>
      </div>
    </header>
  );
}
