"use client"
import Image from "next/image";

export default function RecentFlip() {
    const flips = [
        { imageSrc: "/happy_coin.png", description: "You flipped 0.01 and doubled", time: "5", imageAlt: "Happy Coin" },
        { imageSrc: "/sad_coin.png", description: "You flipped 2.5 and got rugged", time: "7", imageAlt: "Sad Coin" },
        { imageSrc: "/happy_coin.png", description: "You flipped 6 and doubled", time: "10", imageAlt: "Happy Coin" },
       ];

       const handleButtonClick = () => {
        console.log("GO BACK button clicked");
      };


  return (
    <div className="relative flex justify-center items-center min-h-screen overflow-hidden">
      <div
        className="recentflip md:w-[560px] md:h-[374px] md:min-w-[280px]
          md:max-w-[560px] w-[90%] h-[374px] min-w-[280px]
          max-w-[95%]"
      >
        <h2 className="w-[512px] md:h-[116px] h-[100px] text-2xl">
          MY RECENT FLIPS
        </h2>
        <div>
         
         

         {flips.map((flip, index ) => (
             <div key={index} className={`flex items-center justify-between content ${index < 2 ? "border-b border-gray-400" : "null" } `} >
             <div className="flex items-center gap-4">
               <Image
                 alt={flip.imageAlt}
                 src={flip.imageSrc}
                 width={49}
                 height={51}
               />
               <p>{flip.description} </p>
             </div>
             <p className="text-[#333] text-xs">{flip.time} minutes ago </p>
           </div>
         ))}



        </div>

        <div className="mt-5">
          <button
            className="bg-[rgba(242, 199, 28, 1)] text-sm font-semibold w-[100%] 
              h-[40px] btns"
             onClick={handleButtonClick}
          >
            GO BACK
          </button>
        </div>
      </div>
    </div>
  );
}
