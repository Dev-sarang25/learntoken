# LearnToken

A Solidity smart contract that combines an ERC-20 token with an integrated competitive Minesweeper game for token holders.

## Overview

LearnToken is an educational ERC-20 token implementation that includes a unique on-chain Minesweeper game where two token holders can compete against each other in strategic mine placement and block revealing challenges.

## Token Features

### Basic ERC-20 Functionality
- **Name**: Learn Token
- **Symbol**: LEARN
- **Decimals**: 18
- **Initial Supply**: Set at deployment

### Token Operations
- ✅ Transfer tokens between accounts
- ✅ Mint new tokens (owner only)
- ✅ Check balances
- ✅ Transfer ownership

## Minesweeper Game Rules

### Prerequisites
- Both players must hold LEARN tokens to participate
- Players cannot play against themselves

### Game Setup
1. Any token holder can create a game by calling `createGame(opponentAddress)`
2. Game ID is assigned automatically
3. The board consists of 100 blocks (numbered 1-100)

### Game Phases

#### **Round Structure**
The game progresses through 5 rounds with alternating mining and sweeping phases:

| Round | Mines to Place | Blocks to Reveal |
|-------|---------------|------------------|
| 1     | 10            | 5                |
| 2     | 5             | 2                |
| 3     | 2             | 1                |
| 4     | 2             | 1                |
| 5+    | 1             | 1                |

After round 5, the game ends and the winner is determined by score.

#### **Mining Phase**
- Each player has **5 minutes** to place their mines
- Select block numbers between 1-100
- Submit all mine positions at once via `placeMines(gameId, [blockNumbers])`
- ⚠️ **Critical Rule**: Mining an already-mined block results in **instant loss**

#### **Sweeping Phase**
- Each player has **3 minutes** to reveal blocks
- Choose blocks to reveal via `revealBlocks(gameId, [blockNumbers])`
- 💣 Revealing a mined block results in **instant loss**
- Safe reveals earn points based on distance to nearest mine

### Scoring System

When you reveal a safe block, you earn points:
- **Score = 101 - distance to nearest mine**
- Closer to mines = Higher risk = More points

### Distance Messages

When revealing safe blocks, you'll receive feedback:

| Distance | Message |
|----------|---------|
| 1 | "CRITICAL - Mine adjacent!" |
| 2-3 | "DANGER - Very close!" |
| 4-5 | "Warning - Close proximity" |
| 6-10 | "Caution - Mines nearby" |
| 11-20 | "Moderate distance" |
| 20+ | "Far from mines" |

### Winning Conditions

A player wins by:
1. **Opponent hits a mine** during sweeping
2. **Opponent mines an already-mined block**
3. **Opponent times out** (fails to act within time limit)
4. **Higher score** after all rounds complete (if no one hits a mine)

