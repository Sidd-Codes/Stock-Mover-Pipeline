"use client";

import { useEffect, useState } from "react";

const API_URL = "https://ksik6p1o6k.execute-api.us-east-1.amazonaws.com/prod/movers";

function formatDate(dateStr) {
  const d = new Date(dateStr + "T00:00:00");
  if (Number.isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export default function Home() {
  const [movers, setMovers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch(API_URL)
      .then((res) => res.json())
      .then((data) => {
        setMovers(data);
        setLoading(false);
      })
      .catch(() => {
        setError("Failed to load data.");
        setLoading(false);
      });
  }, []);

  return (
    <main className="min-h-screen bg-slate-900 text-slate-50 px-6 py-12">
      <div className="max-w-4xl mx-auto">
        <header className="mb-10">
          <p className="inline-flex items-center rounded-full border border-slate-600 bg-slate-800/80 px-3 py-1 text-xs text-slate-200 mb-4">
            Daily Market Snapshot
          </p>
          <h1 className="text-3xl md:text-4xl font-semibold tracking-tight">
            Stock Top Movers
          </h1>
          <p className="text-slate-300 mt-3 max-w-2xl">
            Biggest mover from the watchlist for each trading day. Data updates after market close.
          </p>
        </header>

        {loading && (
          <div className="rounded-2xl border border-slate-700 bg-slate-800/70 p-6 text-slate-300">
            Loading latest movers...
          </div>
        )}

        {error && (
          <div className="rounded-2xl border border-red-700 bg-red-900/40 p-6 text-red-200">
            {error}
          </div>
        )}

        {!loading && !error && movers.length === 0 && (
          <div className="rounded-2xl border border-slate-700 bg-slate-800/70 p-6 text-slate-300">
            No data available yet.
          </div>
        )}

        {!loading && !error && movers.length > 0 && (
          <section className="space-y-4">
            {movers.map((mover) => {
              const gain = !!mover.is_gain;
              return (
                <article
                  key={mover.date}
                  className={`rounded-2xl border p-5 transition-colors ${
                    gain
                      ? "border-emerald-600/70 bg-emerald-900/30"
                      : "border-rose-600/70 bg-rose-900/30"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h2 className="text-xl font-semibold tracking-wide">{mover.ticker}</h2>
                      <p className="text-sm text-slate-300 mt-1">{formatDate(mover.date)}</p>
                    </div>

                    <div className="text-right">
                      <p
                        className={`text-xl font-semibold ${
                          gain ? "text-emerald-200" : "text-rose-200"
                        }`}
                      >
                        {gain ? "+" : ""}
                        {Number(mover.percent_change).toFixed(2)}%
                      </p>
                      <p className="text-sm text-slate-300">
                        Close: ${Number(mover.close_price).toFixed(2)}
                      </p>
                    </div>
                  </div>
                </article>
              );
            })}
          </section>
        )}

        <footer className="mt-10 pt-6 border-t border-slate-700 text-xs text-slate-400">
          Watchlist: AAPL · MSFT · GOOGL · AMZN · TSLA · NVDA
        </footer>
      </div>
    </main>
  );
}