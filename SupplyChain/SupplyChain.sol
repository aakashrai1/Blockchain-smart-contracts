pragma solidity ^ 0.4 .24;

contract SupplyChain {
    
    mapping(address => uint) userBalance;
    
    //mapping(address => uint) choice;
    
    address buyer;
    address seller;
    address Bank;
    mapping(uint => Product) ProductMap;
    uint numProd;
    
    struct Product {
        string name;
        address pSeller;
        address pBuyer;
        uint price;
        ProductStatus status;
        uint pSellerSig;
        uint pBuyerSig;
    }
    
    enum ProductStatus {
        InStock,
        Ordered,
        InTransit,
        IsDelivered
    }
    
    /*enum Signature {
        None,
        True,
        False
    }*/
    
    constructor() public {
        Bank = msg.sender;
    }
    
    function buyerRegister() public {
        buyer = msg.sender;
    }
    
    function sellerRegister() public {
        seller = msg.sender;
    }
    
    modifier isValidProduct(uint _id) {
        require (_id != 0 && _id <= numProd);
        _;
    }
    
    function addProduct(string _name, uint _price) public {
        numProd++;
        ProductMap[numProd] = Product(_name, msg.sender, 0 ,_price, ProductStatus.InStock
        , 0, 0);
    }
    
    function deposit(uint _productId) public payable isValidProduct(_productId) {
        require(ProductMap[_productId].status == ProductStatus.InStock);
        require(ProductMap[_productId].price == msg.value);
        
        userBalance[msg.sender] = msg.value;
        ProductMap[_productId].pBuyer = msg.sender;
        ProductMap[_productId].status = ProductStatus.Ordered;
    }
    
    function shipProduct(uint _productId) public isValidProduct(_productId) {
        // ship the product
        if (ProductMap[_productId].pSeller == msg.sender && 
        ProductMap[_productId].status == ProductStatus.Ordered) {
            ProductMap[_productId].status = ProductStatus.InTransit;
        }
    }
    
    function deliveredAndTransfer(uint _productId, bool _choice) public isValidProduct(_productId) {
        
        require(ProductMap[_productId].pBuyer == msg.sender || ProductMap[_productId].pSeller == msg.sender);
        
        if (ProductMap[_productId].pBuyer == msg.sender) {
            // called by buyer
            if (_choice) {
                ProductMap[_productId].pBuyerSig = 1;
            } else {
                ProductMap[_productId].pBuyerSig = 2;
            }
            confirmTransaction(_productId);
        }
        
        if (ProductMap[_productId].pSeller == msg.sender) {
            // called by seller
            if (_choice) {
                ProductMap[_productId].pSellerSig = 1;
            } else {
                ProductMap[_productId].pSellerSig = 2;
            }
            confirmTransaction(_productId);
        }
    }
    
    function confirmTransaction(uint _id) private {
        if (ProductMap[_id].pBuyerSig == 1 && ProductMap[_id].pSellerSig == 1) {
            // both agree
            uint price = ProductMap[_id].price;
            userBalance[ProductMap[_id].pBuyer] -= price;
            _sendAmt(ProductMap[_id].pSeller, price);
            ProductMap[_id].status = ProductStatus.IsDelivered;
            
        } else {
            if ((ProductMap[_id].pBuyerSig != 0 && ProductMap[_id].pSellerSig != 0) && (ProductMap[_id].pBuyerSig == 2 || ProductMap[_id].pSellerSig == 2)) {
                // one of them disagrees
                
                price = ProductMap[_id].price;
                userBalance[ProductMap[_id].pBuyer] -= price;
                // Refund
                _sendAmt(ProductMap[_id].pBuyer, price);
                ProductMap[_id].status = ProductStatus.InStock;
                ProductMap[_id].pBuyer = 0;
                ProductMap[_id].pBuyerSig = 0;
                ProductMap[_id].pSellerSig = 0;
            }
        }
    }
    
    function _sendAmt(address _to, uint _price) private {
        _to.transfer(_price);
    }
    
    function timeout(uint _id) public {
        if (msg.sender == Bank) {
            if (ProductMap[_id].pSellerSig == 1 && ProductMap[_id].pBuyerSig == 1) {
                // complete the transaction
            } else {
                // dismiss the transaction and refund
                ProductMap[_id].pSellerSig == 0;
                ProductMap[_id].pBuyerSig == 0;
            }
            confirmTransaction(_id);
        }
    }
}

