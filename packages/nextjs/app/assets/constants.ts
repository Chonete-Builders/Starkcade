// set MAX_LEADERBOARD_SIZE here
const MAX_LEADERBOARD_SIZE = 10;

export const MY_FLIPS = [
  {
    imageSrc: "/happy_coin.png",
    description: "You flipped 0.01 and doubled",
    time: "5",
    imageAlt: "Happy Coin",
  },
  {
    imageSrc: "/sad_coin.png",
    description: "You flipped 2.5 and got rugged",
    time: "7",
    imageAlt: "Sad Coin",
  },
  {
    imageSrc: "/happy_coin.png",
    description: "You flipped 6 and doubled",
    time: "10",
    imageAlt: "Happy Coin",
  },
];

export const FLIPS = [
  {
    user: "Ricardish",
    message: "flipped 0.01 and doubled",
    time: "5 min ago",
    icon: "/happy_coin.png",
  },
  {
    user: "ThunderTrader",
    message: "flipped 2.5 and got rugged",
    time: "7 min ago",
    icon: "/sad_coin.png",
  },
  {
    user: "AmazingOctopus",
    message: "flipped 6 and doubled",
    time: "10 min ago",
    icon: "/happy_coin.png",
  },
];

export const TRANSACTIONS = [
  {
    message: "flipped 0.01 and doubled",
    time: "5",
    txnHash: "0x02394u4iun4bjnfeeofnek399ri43494b4jj888888fj4i",
  },
  {
    message: "withdrew 50 STRK to 0x023030w3450430933303345",
    time: "8",
    txnHash: "0x02394u4iun4bjnfeeofnek399ri43494b4jj888888fj4i",
  },
  {
    message: "flipped 0.01 and got rugged",
    time: "20",
    txnHash: "0x02394u4iun4bjnfeeofnek399ri43494b4jj888888fj4i",
  },
  {
    message: "used 0.1 STRK, won 5 STRK",
    time: "30",
    txnHash: "0x02394u4iun4bjnfeeofnek399ri43494b4jj888888fj4i",
  },
];

export const LEADERBOARD = [
  {
    imageSrc: "/starkcade.png",
    username: "User A",
    amount: 10,
    time: 8,
    imageAlt: "User Avatar",
  },
  {
    imageSrc: "/starkcade.png",
    username: "User B",
    amount: 5,
    time: 3,
    imageAlt: "User Avatar",
  },
  {
    imageSrc: "/starkcade.png",
    username: "User C",
    amount: 2.5,
    time: 2,
    imageAlt: "User Avatar",
  },
];

export const LIVE_STATS = [
  {
    imageSrc: "/starkcade.png",
    username: "User X",
    amount: 0.25,
    time: 10,
    imageAlt: "User Avatar",
  },
  {
    imageSrc: "/starkcade.png",
    username: "User Y",
    amount: 5,
    time: 12,
    imageAlt: "User Avatar",
  },
  {
    imageSrc: "/starkcade.png",
    username: "User Z",
    amount: 7.5,
    time: 17,
    imageAlt: "User Avatar",
  },
];

export const CONNECTED_USERS = [
  {
    imageSrc: "/starkcade.png",
    username: "User 1",
    time: 4,
    imageAlt: "User Avatar",
  },
  {
    imageSrc: "/starkcade.png",
    username: "User 2",
    time: 7,
    imageAlt: "User Avatar",
  },
  {
    imageSrc: "/starkcade.png",
    username: "User 3",
    time: 10,
    imageAlt: "User Avatar",
  },
];

export function _update_leaderboard(username: string, amount: number, time: number) {
  // check if user exist or not
  let existingUser = LEADERBOARD.find((entry) => entry.username === username);

  if (existingUser) {
    // update bet amount and time
    existingUser.amount += amount;
    existingUser.time = time;
  } else {
    // push new user if doesn't exist
    LEADERBOARD.push({
      imageSrc: "/starkcade.png",
      username,
      amount,
      time,
      imageAlt: "User Avatar",
    });
  }

  // sort leaderboard depends on amount
  LEADERBOARD.sort((a, b) => {
  // sort depends on amount first
  if (b.amount !== a.amount) 
  {
    return b.amount - a.amount;
  }

  // sort depends on time if the same amount, and the latest will be the front
  return b.time - a.time;
  }

  // keep MAX_LEADERBOARD_SIZE on leaderboard
  if (LEADERBOARD.length > MAX_LEADERBOARD_SIZE) {
    LEADERBOARD.length = MAX_LEADERBOARD_SIZE;
  }
}
