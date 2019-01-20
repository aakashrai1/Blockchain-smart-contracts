pragma solidity ^ 0.4 .24;

contract EscrowServices {

    mapping(address => uint) userBalance;
    mapping(address => uint) choice;
    address buyer;
    address seller;
    address escrow;
    
    constructor() public {
        escrow = msg.sender;
    }
    
    function buyerRegister() public {
        buyer = msg.sender;
    }
    
    function sellerRegister() public {
        seller = msg.sender;
    }
    
    function transferDep(bool _choice) public {
        // 1 => True, 2 => False
        if (_choice) {
            choice[msg.sender] = 1;
        } else {
            choice[msg.sender] = 2;
        }
        _checkTransaction();
    }
    
    function acceptDeposit() payable public {
        userBalance[msg.sender] = msg.value;
    }
    
    function timeout() public {
        if (msg.sender == escrow) {
            if (choice[buyer] == 1 && choice[seller] == 1) {
                // transfer money to seller
                completeTransaction(seller);
            } else {
                // dismiss the transaction
                completeTransaction(buyer);
            }
        }
    }
    
    function _checkTransaction() private {
        if (choice[buyer] == 1 && choice[seller] == 1) {
            // both agreed, transfer money to the seller
            completeTransaction(seller);
            return;
        }
        
        if ((choice[buyer] != 0 && choice[seller] != 0) && (choice[buyer] == 2 || choice[seller] == 2)) {
            // disagrees, return money to the buyer
            completeTransaction(buyer);
            return;
        }
    }
    
    function completeTransaction(address person) private {
        uint price = userBalance[buyer];
        _send(person, price);
        userBalance[buyer] -= price;
        
        // reset the choices
        choice[buyer] = 0;
        choice[seller] = 0;
    }
    
    function _send(address _to, uint _amt) private {
        uint fee = _amt / 100; // 1% fee
        _to.transfer(_amt - fee);
        // transfer fee to escrow account
        escrow.transfer(fee);
    }
    
    function checkChoice() public view returns (uint) {
        return choice[msg.sender];
    }
    
    function ownerAddress() public view returns (address) {
        return escrow;
    }
    
}
