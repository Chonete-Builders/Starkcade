import React from "react";

const StarryBackground = () => {
  return (
    <div className="absolute inset-0 bg-gradient-to-b from-[#243B55] to-[#141E30] overflow-hidden">
      <div
        className="absolute w-[1px] h-[1px] bg-transparent animate-stars"
        style={{
          boxShadow: Array.from({ length: 700 })
            .map(
              () =>
                `${Math.random() * 2000}px ${Math.random() * 2000}px rgba(173, 216, 230, 0.8)`
            )
            .join(", "),
        }}
      ></div>
      <div
        className="absolute w-[2px] h-[2px] bg-transparent animate-stars-slow"
        style={{
          boxShadow: Array.from({ length: 200 })
            .map(
              () =>
                `${Math.random() * 2000}px ${Math.random() * 2000}px rgba(135, 206, 250, 0.8)`
            )
            .join(", "),
        }}
      ></div>
      <div
        className="absolute w-[3px] h-[3px] bg-transparent animate-stars-slower"
        style={{
          boxShadow: Array.from({ length: 100 })
            .map(
              () =>
                `${Math.random() * 2000}px ${Math.random() * 2000}px rgba(70, 130, 180, 0.8)`
            )
            .join(", "),
        }}
      ></div>
    </div>
  );
};

export default StarryBackground;
