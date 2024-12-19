"use client";

import { useState } from "react";
import StarryBackground from "~~/app/starryBackground/_components/starryBackground";

export const ConflipMainPage = () => {
  const [selectedChoice, setSelectedChoice] = useState("");
  const [selectedAmount, setSelectedAmount] = useState(0);

  return (
    <div className="relative flex justify-center items-center min-h-screen text-white overflow-hidden">
      <StarryBackground />

      <div className="relative text-center p-4 space-y-6 z-10">
        <div className="flex justify-center">
          <img
            src="/coin-removebg.png"
            alt="Web3 Arcade Coin"
            className="w-72 h-72 md:w-96 md:h-96 mx-auto"
          />
        </div>

        <div className="flex justify-center relative">
          <button className="flex items-center px-4 py-2 text-sm border border-white rounded-md hover:bg-gray-800 transition">
            <span className="mr-2">⭘</span>
            <span className="underline">INSURANCE w/ SIDE BETS</span>
          </button>
        </div>

        <p className="font-bold text-lg tracking-wide">I LIKE</p>
        <div className="flex justify-center space-x-12 w-full max-w-[312px] mx-auto">
          <button
            onClick={() => setSelectedChoice("Heads")}
            className={`w-36 py-3 bg-yellow-500 text-black border-2 rounded-md font-bold uppercase transition ${
              selectedChoice === "Heads" ? "border-white" : "border-transparent"
            } hover:bg-yellow-400`}
          >
            Heads
          </button>
          <button
            onClick={() => setSelectedChoice("Tails")}
            className={`w-36 py-3 bg-yellow-500 text-black border-2 rounded-md font-bold uppercase transition ${
              selectedChoice === "Tails" ? "border-white" : "border-transparent"
            } hover:bg-yellow-400`}
          >
            Tails
          </button>
        </div>

        <p className="font-bold text-lg tracking-wide">FOR</p>
        <div className="space-y-4">
          <div className="flex justify-center space-x-4">
            {[0.05, 0.1, 0.25].map((amount) => (
              <button
                key={amount}
                onClick={() => setSelectedAmount(amount)}
                className={`w-24 py-2 bg-yellow-500 text-black border-2 rounded-md font-bold transition ${
                  selectedAmount === amount
                    ? "border-white"
                    : "border-transparent"
                } hover:bg-yellow-400`}
              >
                {amount} Strk
              </button>
            ))}
          </div>
          <div className="flex justify-center space-x-4">
            {[0.5, 1, 2].map((amount) => (
              <button
                key={amount}
                onClick={() => setSelectedAmount(amount)}
                className={`w-24 py-2 bg-yellow-500 text-black border-2 rounded-md font-bold transition ${
                  selectedAmount === amount
                    ? "border-white"
                    : "border-transparent"
                } hover:bg-yellow-400`}
              >
                {amount} Strk
              </button>
            ))}
          </div>
        </div>

        <p className="text-red-500 font-semibold text-sm">
          You do not have enough Strk for this flip
        </p>
        <div className="flex justify-center">
          <button className="w-[312px] py-3 bg-yellow-500 text-black border-2 rounded-md font-bold uppercase hover:bg-yellow-400 transition">
            Double or Nothing
          </button>
        </div>
      </div>
    </div>
  );
};
