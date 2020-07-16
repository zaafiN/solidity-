//Task:
//- Register a Property: Property register with its detail and link for more details as URI (add zameen.com urls).
//- Define Property asking value (demand) in Ether
//- By default on register property will not be on Sale.
//- List Property: A function will enable property for sale
//- Buying Request: A request for buying property with offer value
//- Offer Reject: A owner can reject the offer
//- Offer Accept: A owner can accept offer
//- Buy Property against Offer: Transfer ownership on successful transfer


pragma solidity ^0.6.0;
import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract CryptoArteSales is ERC721 {
    
    //Mappings to keep record of data and transactions:
  
    // mapping from tokenId to their owner's token address
    mapping(uint => address payable) private _tokenOwners;
    
    // mapping from URL to the tokenId
    mapping(string  => uint) private _tokenIds;
    
    // mapping from tokenId to the baseValue or starting demand of property
    mapping (uint => uint) private _baseValue;
    
    // mapping from tokenId to check if a tokenId is listed for bidding
    mapping (uint => bool) public _listedTokens;
    
    // mapping from tokenId to the highest bid 
    mapping (uint => uint) private _highestBid;
    
    // mapping from tokenId to the highest bidder's address 
    mapping (uint => address payable) private _highestBidder;
    

event Sent(address indexed payee, uint256 amount, uint256 balance);
event Received(address indexed payer, uint tokenId, uint256 amount, uint256 balance);

 //Counter for TokenId 
    uint256 private _tokenId;
    
    // EOA or address of contract owner
    address payable public contractOwner;
    ERC721 public nftAddress;
    uint256 public currentPrice;
    string private _baseURI;

constructor(address _nftAddress) ERC721("Zameen", "ZMN") public {
require(_nftAddress != address(0) && _nftAddress != address(this));
//require(_currentPrice > 0);
nftAddress = ERC721(_nftAddress);
contractOwner = msg.sender;
}

 function Register(address payable tokenOwner, string memory propertyURL, uint baseValue) public returns (uint256) {
       //initiate the tokenId counter
        _tokenId++;
        // asssign the value of _tokenId counter to newTokenId variable
        uint256 newTokenId = _tokenId;
        // newTokenId minted and ownership assiged 
        _mint(tokenOwner, newTokenId);
        // baseValue saved against newTokenId 
        _baseValue[newTokenId] = baseValue;
        //owner address saved against newTokenId
        _tokenOwners[newTokenId] = tokenOwner;
        //new propertyURL (contains property details) saved against newTokenId
        _setTokenURI(newTokenId, propertyURL);
        //newTokenId saved against propertyURL
        _tokenIds[propertyURL] = newTokenId;
        // setting initial highest bid to base value
        _highestBid[newTokenId] = _baseValue[newTokenId];
        return newTokenId;
    }
    
    
    
     /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_ ) internal virtual override  {
        _baseURI = baseURI_;
    }
 

    
     //function to view listed property's tokenId
    function getTokenId (string memory propertyURL) public view returns (uint) {
        return _tokenIds[propertyURL];
    }
    
    // function to show that ether balance of an address
    function addressBalance (address _address) public view returns (uint) {
     return address(_address).balance;
        
    }
    
    //function to list a tokenId for bidding
    function List (uint tokenId) public returns (bool) {
        require (_tokenOwners[tokenId] == msg.sender); 
        _listedTokens[tokenId] = true;
        return true;
    }
   
    //function to bid or make an offer for a property: takes bid payment in ether and holds it in contract address as escrow
    function Bid (uint tokenId) public payable{
        require (_listedTokens[tokenId] == true ); // to ensure tokenId is listed
        require (_highestBid[tokenId] < msg.value, "Bid was lower than highest bid" ); // to ensure new bid is higher than previous highest bid
       
       //using if and else because in case we already have an existing highest bidder we would have to refund them before updating the records with the new highest bidder
       // if the highest bid is higher than baseValue, then there already is an existing highest bidder who needs to be refunded
       if (_highestBid[tokenId] > _baseValue[tokenId]) {
         payable( _highestBidder[tokenId]).transfer(_highestBid[tokenId]); // refund the existing highest bidder 
        _highestBid[tokenId] = msg.value; // replace highest bid mapping with new bid
        _highestBidder[tokenId] = msg.sender; // replace highest bidder mapping with new bidder
        } 
        else {
        _highestBid[tokenId] = msg.value; // update highest bid mapping
        _highestBidder[tokenId] = msg.sender; // update highest bidder mapping
    }
}

 //function to view the highest bid received for a tokenId
    function viewBid (uint tokenId) public view returns (uint) {
     require (_tokenOwners[tokenId] == msg.sender); // to ensure only the token owner can see the bid
     return _highestBid[tokenId];  
    }
    
    
    bytes32 bidId = keccak256(
            abi.encodePacked(
                msg.sender,
                nftAddress,
                _tokenId,
                currentPrice
                
            )
        );
    

modifier whenNotPaused() {
    _;
}

 //function to accept a bid
 function acceptBid () public payable {
     require (_tokenOwners[_tokenId] == msg.sender); // to ensure that only token owner can accept a bid
     payable(msg.sender).transfer(_highestBid[_tokenId]); // transfer ether from contract address to property owner
     safeTransferFrom(msg.sender,  _highestBidder[_tokenId], _tokenId); //change of ownership, transfer tokenId to bidder
     _tokenOwners[_tokenId] = _highestBidder[_tokenId]; //update new token owner
     delete _highestBidder[_tokenId]; // delete stored data so that new owner can receive new bids 
     delete _highestBid[_tokenId];  // delete stored data to so that new owner can receive new bidders' addresses
     _highestBid[_tokenId] = _baseValue[_tokenId]; //reset hightest bid to basevalue 
     _listedTokens[_tokenId] = false; // unlist tokenId
    }
    
    // function to reject bid
    function rejectBid (uint tokenId) public {
     payable( _highestBidder[tokenId]).transfer(_highestBid[tokenId]); // refund the highest bidder 
     delete _highestBidder[tokenId]; // delete stored data 
     delete _highestBid[tokenId]; //delete stored data 
     _highestBid[tokenId] = _baseValue[tokenId]; //reset highest bid to baseValue  
    
    }
    
/*
* @dev Purchase _tokenId
* @param _tokenId uint256 token ID (painting number)
*/


function purchaseToken(uint tokenId) public payable whenNotPaused {
require(msg.sender != address(0) && msg.sender != address(this));
require(msg.value >= currentPrice);
//require(nftAddress.exists(_tokenId));
address tokenSeller = nftAddress.ownerOf(_tokenId);
nftAddress.safeTransferFrom(tokenSeller, msg.sender, _tokenId);
emit Received(msg.sender, _tokenId, msg.value, address(this).balance);
}

modifier onlyOwner(){
    _;
}

/**
* @dev send / withdraw _amount to _payee
*/
function sendTo(address payable _payee , uint256 _amount) public onlyOwner {
require(_payee != address(0) && _payee != address(this));
require(_amount > 0 && _amount <= address(this).balance);
_payee.transfer(_amount);
emit Sent(_payee, _amount, address(this).balance);
}

/**
* @dev Updates _currentPrice
* @dev Throws if _currentPrice is zero
*/
function setCurrentPrice(uint256 _currentPrice) public onlyOwner {
require(_currentPrice > 0);
currentPrice = _currentPrice;
}

// fallback function to receive bid payments and hold them in contract address
    receive() external payable{
       msg.sender.transfer(msg.value);
   }
   
     fallback() external payable{
             
        }
    

}
