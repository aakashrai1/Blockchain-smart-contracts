/* Akash Rai - 919165908 */
pragma solidity ^ 0.4.13;

contract rockPaperScissorsGame {
    
    // address(this) corresponds to the address of the owner, 
    // we can use it to store (to) and transfer (from) 
    
    address playerA;
    address playerB;
    string public result;
    string public pAChoice;
    string public pBChoice;

    // Check if the user is registered
    // Used in case where player is tring to play without registering
    modifier isPlayerRegistered() {
        
        if (msg.sender != playerA && msg.sender != playerB) {
            revert();
        } else {
            _ ;
        }
    }
    
    // Check if user is passing valid choice string 
    modifier validChoice(string choice) {
        
        if (
            keccak256(abi.encodePacked(choice)) != keccak256(abi.encodePacked("rock")) && 
            keccak256(abi.encodePacked(choice)) != keccak256(abi.encodePacked("paper")) && 
            keccak256(abi.encodePacked(choice)) != keccak256(abi.encodePacked("scissors"))
            ) {
                revert();    
            } else {
                _ ;    
            }
    }
    
    // Check if player provides enough ethers to play the game
    modifier checkEnoughEthers(uint amount) {
        
        if (msg.value != amount) {
            revert();
        } else {
            _ ;
        }
    }
    
    // Check if the player has not already registered
    // Used to check if player is trying to register again
    modifier playerNotAlreadyRegistered() {
        
        if (msg.sender == playerA || msg.sender == playerB) {
            revert();
        } else {
            _ ;
        }
    }
    
    // Register a player in the game, check whether they have sufficient ethers to play the game
    // and also they are not already registered 
    
    function register() public payable
        checkEnoughEthers(5 ether)
        playerNotAlreadyRegistered {
        
        // Assign players as and when they come
        if (playerA == 0) {
            playerA = msg.sender;
        } else {
            if (playerB == 0) {
                playerB = msg.sender;    
            }
        }
    }
    
    // Check if player has provided a valid choice to play the Game
    // and he/she is regsitered with ethers before playing

    function play(string choice) public
        validChoice(choice)
        isPlayerRegistered {
            
        if (msg.sender == playerA) {
            pAChoice = choice;
        } else {
            if (msg.sender == playerB) {
                pBChoice = choice;
            }
            
        }
    }
    
    // Used to get the result of the game
    
    function getResultOfTheGame() public returns (int r, string response) {
        
        if (bytes(pAChoice).length != 0 && bytes(pBChoice).length != 0) {
            
            int res = getWinner(pAChoice, pBChoice);
            
            if (res == 0) {
                // Game tied
                playerA.transfer(address(this).balance/2);
                playerB.transfer(address(this).balance);
                result = "It's a tie";
                
            } else if (res == 1) {
                // Player A won
                playerA.transfer(address(this).balance);
                result = "Player A won";   
                
            } else {
                // Player B won
                playerB.transfer(address(this).balance);
                result = "Player B won";  
            }

            // Resetting choices after the game
            pAChoice = "";
            pBChoice = "";
            playerA = 0;
            playerB = 0;
            
            return (res, result);
        } else {
            // Another player not yet ready
            return (-1, "Another player is not ready, please try again later");
        }
    }
    
    function getWinner(string p1, string p2) pure private returns (int winner) {
        
      if (keccak256(abi.encodePacked(p1)) == keccak256(abi.encodePacked(p2))) {
        return 0;
      }
      
      if ( (keccak256(abi.encodePacked(p1)) == keccak256(abi.encodePacked("paper"))
        && keccak256(abi.encodePacked(p2)) == keccak256(abi.encodePacked("rock")) )
        || (keccak256(abi.encodePacked(p1)) == keccak256(abi.encodePacked("scissors"))  
        && keccak256(abi.encodePacked(p2)) == keccak256(abi.encodePacked("paper")) )
        || (keccak256(abi.encodePacked(p1)) == keccak256(abi.encodePacked("rock"))
        && keccak256(abi.encodePacked(p2)) == keccak256(abi.encodePacked("scissors")) ) ) {
            
            return 1;
      } else {
        return 2;
      }
    }
    
}
