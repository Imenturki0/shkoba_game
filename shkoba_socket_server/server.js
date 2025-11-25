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
  return results[0] || [];
}

function checkGameEnd(game) {
  const allHandsEmpty = game.players.every((p) => game.hands[p].length === 0);
  return game.deck.length === 0 && allHandsEmpty;
}

function calculateResults(game) {
  const results = {};
  game.players.forEach((player) => {
    results[player] = game.eatenCards[player].length;
  });
  return results;
}

// Pass room as parameter
function advanceTurn(game, room) {
  if (!game.currentTurn) return;

  let currentIndex = game.players.indexOf(game.currentTurn);
  let nextIndex = (currentIndex + 1) % game.players.length;
  let loopedOnce = false;

  while (!game.connected[game.players[nextIndex]]) {
    nextIndex = (nextIndex + 1) % game.players.length;
    if (nextIndex === currentIndex) {
      loopedOnce = true;
      break;
    }
  }

  game.currentTurn = loopedOnce ? null : game.players[nextIndex];

  io.to(room).emit("update_state", {
    tableCards: game.tableCards,
    hands: game.hands,
    eatenCards: game.eatenCards,
    chkobba: game.chkobbaCount,
    currentTurn: game.currentTurn
  });
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
        currentTurn: null,
        connected: {},
        sockets: {},
        disconnectTimers: {}
      };
    }

    const game = rooms[room];

    // Track player's socket
    game.sockets[player] = socket.id;
    game.connected[player] = true;

    // cancel disconnect timer if reconnecting
    if (game.disconnectTimers[player]) {
      clearTimeout(game.disconnectTimers[player]);
      delete game.disconnectTimers[player];
      console.log(`${player} reconnected in time`);
    }

    if (!game.players.includes(player)) {
      game.players.push(player);
      game.hands[player] = game.deck.splice(0, 3);
      game.eatenCards[player] = [];
      game.chkobbaCount[player] = 0;
      if (!game.currentTurn) game.currentTurn = player;
    }

    socket.emit("initial_state", {
      hand: game.hands[player],
      tableCards: game.tableCards,
      eatenCards: game.eatenCards[player],
      chkobba: game.chkobbaCount[player],
      currentTurn: game.currentTurn
    });
    console.log("who turn:", game.currentTurn);
  });

  socket.on("play_card", ({ room, player, cardSuit, cardValue }) => {
    const game = rooms[room];
    if (!game) return;

    const playedCard = { suit: cardSuit, value: cardValue };
    const hand = game.hands[player];
    const index = hand.findIndex((c) => c.suit === cardSuit && c.value === cardValue);
    if (index === -1) return;
    hand.splice(index, 1);

    let captured = [];
    const match = game.tableCards.find((c) => c.value === cardValue);
    if (match) {
      captured.push(match, playedCard);
      game.tableCards = game.tableCards.filter((c) => c !== match);
    } else {
      const subset = findSubsetSum(game.tableCards, cardValue);
      if (subset.length) {
        captured.push(...subset, playedCard);
        game.tableCards = game.tableCards.filter((c) => !subset.includes(c));
      } else {
        game.tableCards.push(playedCard);
      }
    }

    if (captured.length) {
      game.eatenCards[player].push(...captured);
      if (game.tableCards.length === 0) game.chkobbaCount[player]++;
    }

    // Move turn to next connected player
    advanceTurn(game, room);
  });

  socket.on("draw_cards", ({ room, player }) => {
    const game = rooms[room];
    if (!game) return;

    const anyHandNotEmpty = game.players.some((p) =>  game.connected[p] && game.hands[p].length > 0);
    if (anyHandNotEmpty) {
      socket.emit("draw_not_allowed", { message: "Other players still have cards!" });
      return;
    }

    const cardsPerPlayer = 3;
    const totalPlayers = game.players.length;
    let remainingDeck = game.deck.length;

    if (remainingDeck >= cardsPerPlayer * totalPlayers) {
      game.players.forEach((player) => {
        const drawn = game.deck.splice(0, cardsPerPlayer);
        game.hands[player].push(...drawn);
      });
    } else {
      const baseCards = Math.floor(remainingDeck / totalPlayers);
      const extraCards = remainingDeck % totalPlayers;
      game.players.forEach((p, idx) => {
        const count = baseCards + (idx < extraCards ? 1 : 0);
        const drawn = game.deck.splice(0, count);
        game.hands[p].push(...drawn);
      });
    }

    io.to(room).emit("update_state", {
      tableCards: game.tableCards,
      hands: game.hands,
      eatenCards: game.eatenCards,
      chkobba: game.chkobbaCount,
      currentTurn: game.currentTurn
    });

    if (checkGameEnd(game)) {
      const results = calculateResults(game);
      io.to(room).emit("game_over", { results });
    }
  });

  socket.on("restart_game", ({ room }) => {
    const game = rooms[room];
    if (!game) return;

    const deck = createDeck();
    game.deck = deck;
    game.tableCards = game.deck.splice(0, 4);

    game.players.forEach((player) => {
      game.hands[player] = game.deck.splice(0, 3);
      game.eatenCards[player] = [];
      game.chkobbaCount[player] = 0;
    });

    game.currentTurn = game.players[0];

    io.to(room).emit("update_state", {
      tableCards: game.tableCards,
      hands: game.hands,
      eatenCards: game.eatenCards,
      chkobba: game.chkobbaCount,
      currentTurn: game.currentTurn
    });
  });

  socket.on("disconnect", () => {
    console.log("User disconnected:", socket.id);

    for (const room in rooms) {
      const game = rooms[room];
      const player = game.players.find((p) => game.sockets[p] === socket.id);
      if (player) {
        console.log(`${player} disconnected from room ${room}`);
        game.connected[player] = false;

        // Start a timer for reconnection
        game.disconnectTimers[player] = setTimeout(() => {
          console.log(`${player} did not reconnect in time. Skipping turn.`);
          delete game.disconnectTimers[player];

          if (game.currentTurn === player) {
            advanceTurn(game, room);
          }
        }, 30000);
      }
    }
  });
});
