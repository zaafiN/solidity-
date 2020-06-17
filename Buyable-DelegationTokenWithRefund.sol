pragma solidity^0.6.0;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract MyBuyableExToken is IERC20 {
    
      using SafeMath for uint256;
      

     using Address for address;
    
    address public contractAddress = address(this);
    address public contractOwner;
    address public delegate;
    
    //mapping to keep balances
    mapping (address => uint256) private _balances;
    
    //mapping to keep allowances
    //      tokenOwner           spender    amount
    mapping (address => mapping (address => uint256)) private _allowances;
    
    //mapping to keep time when token is bought
    mapping (address => uint256) public timeOfBoughtTokens;
    
    
    //the amount of tokens in existence
    uint256 private _totalSupply;
    
    //price of tokens
    uint256 public tokenPrice;

    string public name;
    string public symbol;
    uint256 public decimals;
    
    
    //events
    event PriceAdjusted(
        bool success,
        uint256 price
    );
    
    event TokensSold(
        address owner,
        address recipient,
        uint256 numberOfTokens
    );
    
    event tokensReturned(
        uint256 _numberOfWeiTokens,
        address tokenOwner,
        uint256 _amount
    );
    
    event OwnerChanged(
        bool success,
        address newContractOwner,
        uint256 amount
    );
    
    event Delegation(
        bool success,
        address _delegate
    );
    
    event AmountWithDraw(
        bool success,
        address contractOwner,
        uint256 amount
    );
    
    
    event AmountReceived(string);
    
    
    constructor(uint256 _price) public payable {
        require(_price > 0, "token price must be valid");
        
        name = "Buyable-Ex-Token";
        symbol = "BET";
        decimals = 18;
        contractOwner = msg.sender;
        tokenPrice = _price;
        
        //1 million tokens generated
        _totalSupply = 1000000 * (10 ** decimals);
        
        //transfer totalsupply to contractOwner
        _balances[contractOwner] = _totalSupply;
        
        //emit Transfer event
        emit Transfer(address(this), contractOwner, _totalSupply);
    }
    
    
    /**
     * Function modifier to restrict Owner's transactions.
     */
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "MyBuyableExToken: Only contract owner allowed");
        _;
    }
    
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account]; 
    }
    
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     * 
     * - `sender` and `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns(bool) {
        address sender = msg.sender;
        
        require(sender != address(0), "MyBuyableExToken: transfer from the zero address");
        require(recipient != address(0), "MyBuyableExToken: transfer to the zero address");
        require(_balances[sender] > amount, "MyBuyableExToken: Insufficient balance");
        
        //decrease the balance of token sender account
        _balances[sender] = _balances[sender].sub(amount); 
        
        //increase the balance of token recipient account
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address tokenOwner, address spender) external view override returns(uint256) {
        return _allowances[tokenOwner][spender];
    } 
    
    
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns(bool) {
        address tokenOwner = msg.sender;
        
        require(tokenOwner != address(0), "MyBuyableExToken: approve from the zero address");
        require(spender != address(0), "MyBuyableExToken: approve to the zero address");
        require(_balances[tokenOwner] >= amount, "MyBuyableExToken: caller is either not the tokenOwner or has insufficient balance");
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
        return true;
    }
    
    
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     * here sender is the tokenOwner
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller(spender) must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[sender][spender];
        
        require(sender != address(0), "MyBuyableExToken: transfer from the zero address");
        require(recipient != address(0), "MyBuyableExToken: transfer to the zero address");
        require(_balances[sender] > amount, "MyBuyableExToken: transfer amount exceeds balance");
        require(_allowance > amount, "MyBuyableExToken: transfer amount exceeds allowance");
        
        //deducting the allowance
        _allowance = _allowance.sub(amount);
        
        // ---Transfer execution---
        
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient].add(amount);
        
        //owner decrease balance
        _balances[sender] =_balances[sender].sub(amount); 
        
        emit Transfer(sender, recipient, amount);
        // ---end execution--
        
        //decrease the approval amount
        _allowances[sender][spender] = _allowance;
        
        emit Approval(sender, spender, amount);
        
        return true;
    }
    
     function adjustPrice(uint256 _price) public returns(bool) {
        require((msg.sender == contractOwner) || (msg.sender == delegate), "MyBuyableExToken: Only contract owner or delegate allowed");
        require(_price > 0, "MyBuyableExToken: token price must be valid");
        
        tokenPrice = _price;
        
        emit PriceAdjusted(true, _price);
        return true;
    }
    
    
        // struct to record buying details 
    struct BuyDetails {
        uint256 buyTime;
        uint256 tokenUnitsInWeiToBuy; // shows the smallest units of token bought 
        uint256 weiReceived; // the units of wei received from a buy transaction
        uint256 tokenBuyingRate; // the rate of smallest unit if token against wei, at the time of buying
        uint256 tokensLeft; // tokens left after any refund
        uint256 noOfTokensBuy;
    }
    
    mapping (address => BuyDetails) public buyerDetails; // to record buy details against an address that made the Purchase
    
    // function to allow an address to buy tokens 
    function buyToken(address payable buyer) public payable virtual returns (bool) {
        require(tx.origin == buyer); // to ensure transaction is initiated by EOA
        
        uint256 noOfTokensBuy = msg.value / tokenPrice;// if needed, calculates the no of tokens bought
       
        uint256 weiReceived = msg.value; // wei paid by the buyer
       
        uint256 tokenUnitsInWeiToBuy = (msg.value.mul(10**decimals)).div(tokenPrice); // calculates the smallest units of token bought
       
        uint256 tokenBuyingRate = tokenPrice; // the rate at which the purchase was made
        
        uint256 tokensMayRefund = tokenUnitsInWeiToBuy; // Number of tokens of buyer for  any refund
      
      _balances[buyer] =  _balances[buyer].add(tokenUnitsInWeiToBuy); // adds the tokens bought to buyer balance
      
      _balances[contractOwner] =  _balances[contractOwner].sub(tokenUnitsInWeiToBuy); // subtracts the tokens from the owner balance
      
      _balances[contractAddress] =  _balances[contractAddress].add(msg.value); //adds the wei received to the above defined weiReceipt address
        
        uint256 buyTime = block.timestamp; // records the time of purchase
        
        //update the struct with BuyDetails
        buyerDetails[buyer] = BuyDetails(buyTime, tokenUnitsInWeiToBuy, weiReceived, tokenBuyingRate, tokensMayRefund, noOfTokensBuy);
      
       return true;
      
    }
    
    /**
     * This function will allow to get balance of contract
     * 
     * Requirements:
     * - the caller must be valid
     */
    function getContractBalance() public view returns (uint256) {
        require(msg.sender != address(0), "MyBuyableExToken: Address must be valid");
        return address(this).balance;
    }
    
    /**
     * This function will allow owner to withdraw ethers stored in contact
     * 
     * Requirements:
     * - the caller must be Owner of Contract
     * - amount must be valid
     */
    function withDraw(uint256 _amount) public onlyOwner() returns(bool) {
        require(_amount > 0, "MyBuyableExToken: Amount must be valid");
        require(_amount <= address(this).balance, "MyBuyableExToken: Insufficient Balance");
        
        payable(contractOwner).transfer(_amount);
        
         AmountWithDraw(true, contractOwner, _amount);
        
        return true;
    } 
    
    /**
     * This function will allow owner to change ownership to another valid address
     * 
     * Requirements:
     * - the caller must be Owner of Contract
     * - thw new owner must be valid
     * - amount must be valid
     */
    function changeOwner(address newContractOwner, uint256 amount) public onlyOwner() returns(bool) {
        require(newContractOwner != address(0), "MyBuyableExToken: Address must be valid");
        require(amount > 0, "MyBuyableExToken: Amount must be valid");
        if(newContractOwner == contractOwner) {
            revert("MyBuyableExToken: The provided address is already the owner");
        }
        
        transfer(payable(newContractOwner), amount);
        
        contractOwner = newContractOwner;
        
         emit OwnerChanged(true, newContractOwner, _balances[newContractOwner]);
        
        return true;
    } 
    
    function approveDelegate(address _delegate) public onlyOwner() returns(bool) {
        require(_delegate != address(0), "MyBuyableExToken: Address must be valid");
        
        delegate = _delegate;
        
        emit Delegation(true, _delegate);
        return true;
    }
     function returnToken(uint256 _numberOfWeiTokens) public returns(bool) {
        address tokenOwner = msg.sender;
        
        require(tokenOwner != address(0), "MyBuyableExToken: caller cannot be zero address");
        require(_balances[tokenOwner] >= _numberOfWeiTokens, "MyBuyableExToken: caller is either not the tokenOwner or has insufficient balance");
        
        require(block.timestamp <= (timeOfBoughtTokens[tokenOwner]).add(2592000), "MyBuyableExToken: Return only possible within the limited time"); //1 month = 2592000 secs
                                                                     
        
        //converts numberOfTokens to value(money) based on current tokenPrice
        uint256 _amount = _numberOfWeiTokens.mul(10**decimals).div(tokenPrice);
        
        require(_amount > 0, "MyBuyableExToken: Amount must be valid");
        require(_amount <= address(this).balance, "MyBuyableExToken: Insufficient Balance");
        
        //transfers tokens back to contractOwner 
        transfer(contractOwner, _numberOfWeiTokens);
        
        //transfers money back to the tokenOwner
        payable(msg.sender).transfer(_amount);
        
        //event fire
        emit tokensReturned(_numberOfWeiTokens, tokenOwner, _amount);
        
        return true;
    }
    
      fallback() external payable {
        buyToken(msg.sender);
        emit AmountReceived("fallback");
    }
    
    receive() external payable {
        buyToken(msg.sender);
        emit AmountReceived("receive fallback");
    }
    
}

