"use client";
// app/trades/page.tsx — Phase 2 locked screen
import Link from "next/link";
export default function TradesPage() {
  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
      <div className="text-center max-w-sm">
        <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl">🔒</div>
        <h1 className="text-2xl font-bold text-slate-900 mb-2">Local Trades</h1>
        <p className="text-slate-500 mb-6 leading-relaxed">Local Trades is coming in Phase 2. Pre-register now to be first in the directory when your neighbours start searching!</p>
        <Link href="/market" className="inline-block w-full py-3 rounded-xl bg-emerald-700 text-white font-semibold text-sm hover:bg-emerald-800 text-center">← Back to Hub</Link>
      </div>
    </div>
  );
}
