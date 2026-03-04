"use client";

import { useEffect, useState } from "react";

const API_URL = "https://ksik6p1o6k.execute-api.us-east-1.amazonaws.com/prod/movers";

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
      .catch((err) => {
        setError("Failed to load data.");
        setLoading(false);
      });
  }, []);

  return (
    <main className="min-h-screen bg-gray-950 text-white px-6 py-12">
      <div className="max-w-3xl mx-auto">

        <h1 className="text-3xl font-bold mb-2 tracking-tight">
          📈 Stock Top Mover
        </h1>
        <p className="text-gray-400 mb-8 text-sm">
          The single biggest mover from our watchlist each day — updated automatically after market close.
        </p>

        {loading && (
          <p className="text-gray-400">Loading...</p>
        )}

        {error && (
          <p className="text-red-400">{error}</p>
        )}

        {!loading && !error && movers.length === 0 && (
          <p className="text-gray-400">No data available yet.</p>
        )}

        {!loading && !error && movers.length > 0 && (
          <div className="flex flex-col gap-4">
            {movers.map((mover) => (
              <div
                key={mover.date}
                className={`rounded-xl px-6 py-5 border ${
                  mover.is_gain
                    ? "bg-green-950 border-green-700"
                    : "bg-red-950 border-red-700"
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xl font-bold tracking-wide">
                    {mover.ticker}
                  </span>
                  <span
                    className={`text-lg font-semibold ${
                      mover.is_gain ? "text-green-400" : "text-red-400"
                    }`}
                  >
                    {mover.is_gain ? "+" : ""}
                    {mover.percent_change.toFixed(2)}%
                  </span>
                </div>
                <div className="flex items-center justify-between text-sm text-gray-400">
                  <span>{mover.date}</span>
                  <span>Close: ${mover.close_price.toFixed(2)}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        <p className="text-gray-600 text-xs mt-10 text-center">
          Watchlist: AAPL · MSFT · GOOGL · AMZN · TSLA · NVDA
        </p>

      </div>
    </main>
  );
}