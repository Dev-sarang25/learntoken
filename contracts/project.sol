// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LearnToken with Minesweeper Game
 * @notice ERC-20 token with an integrated Minesweeper game for token holders
 * @dev Players compete by placing mines and revealing blocks
 */
contract LearnToken {
    // Token metadata
    string public name = "Learn Token";
    string public symbol = "LEARN";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    address public owner;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GameCreated(uint256 indexed gameId, address player1, address player2);
    event MinesPlaced(uint256 indexed gameId, address player, uint256 round);
    event BlockRevealed(uint256 indexed gameId, address player, uint256 blockNum, string result);
    event GameOver(uint256 indexed gameId, address winner, string reason);
    
    // Minesweeper Game Structures
    enum GamePhase { Mining, Sweeping }
    enum RoundType { Ten, Five, Two1, Two2, One }
    
    struct Game {
        address player1;
        address player2;
        mapping(uint256 => address) minedBy; // block number => player who mined it
        mapping(address => bool) hasPlacedMines;
        mapping(address => bool) hasSwept;
        GamePhase phase;
        RoundType round;
        uint256 startTime;
        bool active;
        address winner;
        uint256 player1Score;
        uint256 player2Score;
    }
    
    mapping(uint256 => Game) public games;
    uint256 public gameCounter;
    uint256 public constant MINING_TIME_LIMIT = 5 minutes;
    uint256 public constant SWEEPING_TIME_LIMIT = 3 minutes;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply * 10**decimals);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool success) {
        _mint(_to, _amount);
        return true;
    }
    
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "Cannot mint to zero address");
        
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
    
    function getBalance(address _account) public view returns (uint256 balance) {
        return balanceOf[_account];
    }
    
    // ========== MINESWEEPER GAME FUNCTIONS ==========
    
    /**
     * @notice Create a new Minesweeper game between two token holders
     * @param _opponent The address of the opponent
     * @return gameId The ID of the created game
     */
    function createGame(address _opponent) public returns (uint256 gameId) {
        require(balanceOf[msg.sender] > 0, "Must hold tokens to play");
        require(balanceOf[_opponent] > 0, "Opponent must hold tokens");
        require(_opponent != msg.sender, "Cannot play against yourself");
        
        gameId = gameCounter++;
        Game storage game = games[gameId];
        
        game.player1 = msg.sender;
        game.player2 = _opponent;
        game.phase = GamePhase.Mining;
        game.round = RoundType.Ten;
        game.startTime = block.timestamp;
        game.active = true;
        
        emit GameCreated(gameId, msg.sender, _opponent);
    }
    
    /**
     * @notice Get the number of mines to place for current round
     */
    function getMinesForRound(RoundType round) internal pure returns (uint256) {
        if (round == RoundType.Ten) return 10;
        if (round == RoundType.Five) return 5;
        if (round == RoundType.Two1 || round == RoundType.Two2) return 2;
        return 1; // RoundType.One
    }
    
    /**
     * @notice Get the number of blocks to sweep for current round
     */
    function getSweepsForRound(RoundType round) internal pure returns (uint256) {
        if (round == RoundType.Ten) return 5;
        if (round == RoundType.Five) return 2;
        return 1; // Two1, Two2, One
    }
    
    /**
     * @notice Place mines on the board (space-separated numbers 1-100)
     * @param _gameId The game ID
     * @param _blockNumbers Array of block numbers to mine (1-100)
     */
    function placeMines(uint256 _gameId, uint256[] memory _blockNumbers) public {
        Game storage game = games[_gameId];
        
        require(game.active, "Game not active");
        require(msg.sender == game.player1 || msg.sender == game.player2, "Not a player");
        require(game.phase == GamePhase.Mining, "Not mining phase");
        require(!game.hasPlacedMines[msg.sender], "Already placed mines this round");
        require(block.timestamp <= game.startTime + MINING_TIME_LIMIT, "Mining time expired");
        
        uint256 expectedMines = getMinesForRound(game.round);
        require(_blockNumbers.length == expectedMines, "Wrong number of mines");
        
        // Validate and place mines
        for (uint256 i = 0; i < _blockNumbers.length; i++) {
            uint256 blockNum = _blockNumbers[i];
            require(blockNum >= 1 && blockNum <= 100, "Block must be 1-100");
            
            // Check if already mined
            if (game.minedBy[blockNum] != address(0)) {
                // Mining already mined block = instant lose
                game.active = false;
                game.winner = (msg.sender == game.player1) ? game.player2 : game.player1;
                emit GameOver(_gameId, game.winner, "Opponent mined already mined block");
                return;
            }
            
            game.minedBy[blockNum] = msg.sender;
        }
        
        game.hasPlacedMines[msg.sender] = true;
        emit MinesPlaced(_gameId, msg.sender, uint256(game.round));
        
        // Check if both players placed mines
        if (game.hasPlacedMines[game.player1] && game.hasPlacedMines[game.player2]) {
            _advanceToSweeping(_gameId);
        }
    }
    
    /**
     * @notice Reveal blocks during sweeping phase
     * @param _gameId The game ID
     * @param _blockNumbers Array of block numbers to reveal (1-100)
     */
    function revealBlocks(uint256 _gameId, uint256[] memory _blockNumbers) public {
        Game storage game = games[_gameId];
        
        require(game.active, "Game not active");
        require(msg.sender == game.player1 || msg.sender == game.player2, "Not a player");
        require(game.phase == GamePhase.Sweeping, "Not sweeping phase");
        require(!game.hasSwept[msg.sender], "Already swept this round");
        require(block.timestamp <= game.startTime + SWEEPING_TIME_LIMIT, "Sweeping time expired");
        
        uint256 expectedSweeps = getSweepsForRound(game.round);
        require(_blockNumbers.length == expectedSweeps, "Wrong number of sweeps");
        
        // Process reveals
        for (uint256 i = 0; i < _blockNumbers.length; i++) {
            uint256 blockNum = _blockNumbers[i];
            require(blockNum >= 1 && blockNum <= 100, "Block must be 1-100");
            
            if (game.minedBy[blockNum] != address(0)) {
                // Hit a mine!
                game.active = false;
                game.winner = (msg.sender == game.player1) ? game.player2 : game.player1;
                emit BlockRevealed(_gameId, msg.sender, blockNum, "BOOM! Hit a mine");
                emit GameOver(_gameId, game.winner, "Opponent hit a mine");
                return;
            } else {
                // Safe block - calculate distance to nearest mine
                uint256 distance = _findNearestMineDistance(_gameId, blockNum);
                string memory result = _getDistanceMessage(distance);
                
                if (msg.sender == game.player1) {
                    game.player1Score += (101 - distance); // Closer = more points
                } else {
                    game.player2Score += (101 - distance);
                }
                
                emit BlockRevealed(_gameId, msg.sender, blockNum, result);
            }
        }
        
        game.hasSwept[msg.sender] = true;
        
        // Check if both players swept
        if (game.hasSwept[game.player1] && game.hasSwept[game.player2]) {
            _advanceRound(_gameId);
        }
    }
    
    /**
     * @notice Advance from mining to sweeping phase
     */
    function _advanceToSweeping(uint256 _gameId) internal {
        Game storage game = games[_gameId];
        game.phase = GamePhase.Sweeping;
        game.startTime = block.timestamp;
        game.hasPlacedMines[game.player1] = false;
        game.hasPlacedMines[game.player2] = false;
    }
    
    /**
     * @notice Advance to next round or end game
     */
    function _advanceRound(uint256 _gameId) internal {
        Game storage game = games[_gameId];
        
        // Progress through rounds: Ten -> Five -> Two1 -> Two2 -> One (repeats)
        if (game.round == RoundType.Ten) {
            game.round = RoundType.Five;
        } else if (game.round == RoundType.Five) {
            game.round = RoundType.Two1;
        } else if (game.round == RoundType.Two1) {
            game.round = RoundType.Two2;
        } else if (game.round == RoundType.Two2) {
            game.round = RoundType.One;
        } else {
            // Game ends after One round - determine winner by score
            game.active = false;
            if (game.player1Score > game.player2Score) {
                game.winner = game.player1;
            } else if (game.player2Score > game.player1Score) {
                game.winner = game.player2;
            } else {
                game.winner = address(0); // Tie
            }
            emit GameOver(_gameId, game.winner, "Game completed - scored based winner");
            return;
        }
        
        game.phase = GamePhase.Mining;
        game.startTime = block.timestamp;
        game.hasSwept[game.player1] = false;
        game.hasSwept[game.player2] = false;
    }
    
    /**
     * @notice Find distance to nearest mine
     */
    function _findNearestMineDistance(uint256 _gameId, uint256 _blockNum) internal view returns (uint256) {
        Game storage game = games[_gameId];
        uint256 minDistance = 101;
        
        for (uint256 i = 1; i <= 100; i++) {
            if (game.minedBy[i] != address(0)) {
                uint256 distance = (i > _blockNum) ? (i - _blockNum) : (_blockNum - i);
                if (distance < minDistance) {
                    minDistance = distance;
                }
            }
        }
        
        return minDistance;
    }
    
    /**
     * @notice Get message based on distance to nearest mine
     */
    function _getDistanceMessage(uint256 _distance) internal pure returns (string memory) {
        if (_distance == 0) return "Direct hit!";
        if (_distance == 1) return "CRITICAL - Mine adjacent!";
        if (_distance <= 3) return "DANGER - Very close!";
        if (_distance <= 5) return "Warning - Close proximity";
        if (_distance <= 10) return "Caution - Mines nearby";
        if (_distance <= 20) return "Moderate distance";
        return "Far from mines";
    }
    
    /**
     * @notice Check if a block is mined in a game
     */
    function isBlockMined(uint256 _gameId, uint256 _blockNum) public view returns (bool, address) {
        Game storage game = games[_gameId];
        address miner = game.minedBy[_blockNum];
        return (miner != address(0), miner);
    }
    
    /**
     * @notice Get game status
     */
    function getGameStatus(uint256 _gameId) public view returns (
        address player1,
        address player2,
        GamePhase phase,
        RoundType round,
        bool active,
        address winner,
        uint256 player1Score,
        uint256 player2Score,
        uint256 timeRemaining
    ) {
        Game storage game = games[_gameId];
        
        uint256 timeLimit = (game.phase == GamePhase.Mining) ? MINING_TIME_LIMIT : SWEEPING_TIME_LIMIT;
        uint256 elapsed = block.timestamp - game.startTime;
        timeRemaining = (elapsed < timeLimit) ? (timeLimit - elapsed) : 0;
        
        return (
            game.player1,
            game.player2,
            game.phase,
            game.round,
            game.active,
            game.winner,
            game.player1Score,
            game.player2Score,
            timeRemaining
        );
    }
    
    /**
     * @notice Claim win if opponent fails to act in time
     */
    function claimTimeout(uint256 _gameId) public {
        Game storage game = games[_gameId];
        
        require(game.active, "Game not active");
        require(msg.sender == game.player1 || msg.sender == game.player2, "Not a player");
        
        uint256 timeLimit = (game.phase == GamePhase.Mining) ? MINING_TIME_LIMIT : SWEEPING_TIME_LIMIT;
        require(block.timestamp > game.startTime + timeLimit, "Time not expired");
        
        address opponent = (msg.sender == game.player1) ? game.player2 : game.player1;
        
        if (game.phase == GamePhase.Mining) {
            require(game.hasPlacedMines[msg.sender], "You didn't place mines");
            require(!game.hasPlacedMines[opponent], "Opponent placed mines");
        } else {
            require(game.hasSwept[msg.sender], "You didn't sweep");
            require(!game.hasSwept[opponent], "Opponent swept");
        }
        
        game.active = false;
        game.winner = msg.sender;
        emit GameOver(_gameId, msg.sender, "Opponent timeout");
    }
}
