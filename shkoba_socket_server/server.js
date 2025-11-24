const io = require("socket.io")(3000, { cors: { origin: "*" } });

const rooms = {};

function createDeck() {
  const suits = ["c", "d", "h", "s"];
  const deck = [];
  for (let s of suits) {
    for (let i = 1; i <= 13; i++) {
      deck.push({ suit: s, value: i });
    }
  }
  return deck.sort(() => Math.random() - 0.5);
}

// Subset sum helper: returns any subset of tableCards whose sum equals target
function findSubsetSum(tableCards, target) {
  const results = [];

  function backtrack(start, path, sum) {
    if (sum === target) {
      results.push([...path]);
      return;
    }
    if (sum > target || start === tableCards.length) return;

    for (let i = start; i < tableCards.length; i++) {
      path.push(tableCards[i]);
      backtrack(i + 1, path, sum + tableCards[i].value);
      path.pop();
    }
  }

  backtrack(0, [], 0);
  return results[0] || []; // return first subset found or empty
}

function checkGameEnd(game) {
  // Game ends if deck is empty AND all players have empty hands
  const allHandsEmpty = game.players.every((p) => game.hands[p].length === 0);
  return game.deck.length === 0 && allHandsEmpty;
}

function calculateResults(game) {
  const results = {};
  game.players.forEach((player) => {
    results[player] = game.eatenCards[player].length; // number of captured cards
  });
  return results;
}

io.on("connection", (socket) => {
  console.log("New connection:", socket.id);

  socket.on("join_room", ({ room, player }) => {
    socket.join(room);

    if (!rooms[room]) {
      const deck = createDeck();
      rooms[room] = {
        deck,
        tableCards: deck.splice(0, 4),
        players: [],
        hands: {},
        eatenCards: {},
        chkobbaCount: {},
      };
    }

    const game = rooms[room];

    if (!game.players.includes(player)) {
      game.players.push(player);
      game.hands[player] = game.deck.splice(0, 3);
      game.eatenCards[player] = [];
      game.chkobbaCount[player] = 0;
    }

    socket.emit("initial_state", {
      hand: game.hands[player],
      tableCards: game.tableCards,
      eatenCards: game.eatenCards[player],
      chkobba: game.chkobbaCount[player],
    });
  });

  socket.on("play_card", ({ room, player, cardSuit, cardValue }) => {
    const game = rooms[room];
    console.log("captured");
    if (!game) return;

    const playedCard = { suit: cardSuit, value: cardValue };
    const hand = game.hands[player];

    const index = hand.findIndex(
      (c) => c.suit === cardSuit && c.value === cardValue
    );
    if (index === -1) return; // card not in hand
    hand.splice(index, 1);

    let captured = [];
    // 1. Check exact match
    const match = game.tableCards.find((c) => c.value === cardValue);
    if (match) {
      captured.push(match, playedCard);
      game.tableCards = game.tableCards.filter((c) => c !== match);
    } else {
      // 2. Check subset sum
      const subset = findSubsetSum(game.tableCards, cardValue);
      if (subset.length) {
        captured.push(...subset, playedCard);
        game.tableCards = game.tableCards.filter((c) => !subset.includes(c));
      } else {
        // No capture, just place card on table
        game.tableCards.push(playedCard);
      }
    }
    console.log("captured", captured);
    if (captured.length) {
      game.eatenCards[player].push(...captured);
      if (game.tableCards.length === 0) game.chkobbaCount[player]++;
    }
    console.log("captured", captured);
    // Update all clients
    io.to(room).emit("update_state", {
      tableCards: game.tableCards,
      hands: game.hands,
      eatenCards: game.eatenCards,
      chkobba: game.chkobbaCount,
    });
  });

  socket.on("draw_cards", ({ room, player }) => {
    const game = rooms[room];
    if (!game) return;

    if (game.deck.length >= 3) {
      game.hands[player].push(...game.deck.splice(0, 3));
    }

    io.to(room).emit("update_state", {
      tableCards: game.tableCards,
      hands: game.hands,
      eatenCards: game.eatenCards,
      chkobba: game.chkobbaCount,
    });
    // Inside draw_cards or play_card
    if (checkGameEnd(game)) {
      const results = calculateResults(game);
      io.to(room).emit("game_over", { results });
    }
  });

  socket.on('restart_game', ({ room }) => {
  const game = rooms[room];
  if (!game) return;

  // create new shuffled deck
  const deck = createDeck();
  game.deck = deck;
  // reset table and hands
  game.tableCards = game.deck.splice(0, 4);

  // reset per-player things and deal 3 each
  game.players.forEach(player => {
    game.hands[player] = game.deck.splice(0, 3);
    game.eatenCards[player] = [];
    game.chkobbaCount[player] = 0;
  });

  // Broadcast updated state
  io.to(room).emit('update_state', {
    tableCards: game.tableCards,
    hands: game.hands,
    eatenCards: game.eatenCards,
    chkobba: game.chkobbaCount
  });

  console.log(`Room ${room} restarted by a player`);
});



});
