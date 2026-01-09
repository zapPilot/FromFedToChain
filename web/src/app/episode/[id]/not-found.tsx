import Link from "next/link";

export default function NotFound() {
  return (
    <div className="container mx-auto px-4 py-16">
      <div className="max-w-2xl mx-auto text-center">
        <h1 className="text-4xl font-bold mb-4">Episode Not Found</h1>
        <p className="text-zinc-400 mb-8">
          The episode you're looking for doesn't exist or has been removed.
        </p>
        <Link
          href="/"
          className="inline-block px-6 py-3 bg-white text-black rounded-lg font-medium hover:bg-zinc-200 transition-colors"
        >
          Back to Episodes
        </Link>
      </div>
    </div>
  );
}
