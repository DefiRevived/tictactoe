//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
contract TicTacToe {
    // Variables
    uint256 constant public BOARD_SIZE = 3;
    address public player1;
    address public player2;
    uint256 public turn;
    uint256 public winner;
    uint256 public prize;
    uint256 public moveCount;
    mapping (address => uint256) public playerBalance;
    uint256[BOARD_SIZE][BOARD_SIZE] public board;
    bool public gameFinished;
    mapping (address => bool) public hasWithdrawn;

    // Events
    event NewGame(address indexed player1, address indexed player2, uint256 prize);
    event NewMove(address indexed player, uint256 row, uint256 col);
    event GameFinished(address indexed winner, uint256 prize);
    event GameWithdraw(address indexed player, uint256 amount);

    // Constructor
    constructor() {
        player1 = msg.sender;
        turn = 1;
        gameFinished = false;
    }

    // Functions
    function joinGame() public payable {
        require(player2 == address(0), "Game is already full.");
        require(msg.sender != player1, "You cannot play against yourself.");
        require(msg.value > 0, "You must send some ether to play.");
        player2 = msg.sender;
        prize = msg.value;
        emit NewGame(player1, player2, prize);
    }

    function makeMove(uint256 row, uint256 col) public {
        require(!gameFinished, "Game is already finished.");
        require(msg.sender == player1 || msg.sender == player2, "You are not a player in this game.");
        require(board[row][col] == 0, "That spot is already taken.");
        require(turn == 1 && msg.sender == player1 || turn == 2 && msg.sender == player2, "It is not your turn.");

        // Mark the board
        board[row][col] = turn;
        moveCount += 1;

        // Check if there is a winner
        if (isWinner(turn)) {
            // We have a winner!
            winner = turn;
            gameFinished = true;

            // Payout the prize to the winner
            playerBalance[player1] = 0;
            playerBalance[player2] = 0;
            if (winner == 1) {
                playerBalance[player1] = prize;
            } else {
                playerBalance[player2] = prize;
            }
            emit GameFinished(msg.sender, prize);
            return;
        }

        // Check if the game is a tie
        if (moveCount == BOARD_SIZE * BOARD_SIZE) {
            gameFinished = true;

            // Payout the prize to both players
            playerBalance[player1] = prize / 2;
            playerBalance[player2] = prize / 2;
            emit GameFinished(address(0), prize);
            return;
        }

        // Switch turns
        turn = turn == 1 ? 2 : 1;

        // Emit the new move event
        emit NewMove(msg.sender, row, col);
    }

    function isWinner(uint256 player) private view returns (bool) {
        // Check rows
        for (uint256 i = 0; i < BOARD_SIZE; i++) {
            bool won = true;
            for (uint256 j = 0; j < BOARD_SIZE; j++) {
                if (board[i][j] != player) {
                    won = false;
                    break;
                }
            }
            if (won) {
                return true;
            }
        }

        //
// Check columns
for (uint256 i = 0; i < BOARD_SIZE; i++) {
bool won = true;
for (uint256 j = 0; j < BOARD_SIZE; j++) {
if (board[j][i] != player) {
won = false;
break;
}
}
if (won) {
return true;
}
}
    // Check diagonal
    bool won1 = true;
    bool won2 = true;
    for (uint256 i = 0; i < BOARD_SIZE; i++) {
        if (board[i][i] != player) {
            won1 = false;
        }
        if (board[i][BOARD_SIZE - 1 - i] != player) {
            won2 = false;
        }
    }
    if (won1 || won2) {
        return true;
    }

    // No winner yet
    return false;
}

function withdraw() public {
    require(gameFinished, "The game is not yet finished.");
    require(!hasWithdrawn[msg.sender], "You have already withdrawn your balance.");

    uint256 amount = playerBalance[msg.sender];
    require(amount > 0, "You have no balance to withdraw.");

    // Set the flag to prevent reentrancy
    hasWithdrawn[msg.sender] = true;

    // Transfer the funds
    (bool success,) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed.");

    // Emit event
    emit GameWithdraw(msg.sender, amount);
}

// Fallback function
receive() external payable {
    revert();
}
}