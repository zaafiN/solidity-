pragma solidity ^0.6.0;
//0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c
import "./IERC20.sol";
import "./SafeMath.sol";
// SafeMath library will allow to use arthemtic operation on Uint256
contract BuyableTokenWithRefund is IERC20{
    //Extending Uint256 with SafeMath Library.
    using SafeMath for uint256;
    
    //mapping to hold balances against EOA accounts
    mapping (address => uint256) private _balances;

    //mapping to hold approved allowance of token to certain address
    //       Owner               Spender    allowance
    mapping (address => mapping (address => uint256)) private _allowances;

    //the amount of tokens in existence
    uint256 private _totalSupply;

    //owner
    address payable public owner;
    
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public tokenRate;
    address payable weiReceipt;
    address public delegate;
    
 
    constructor () public {
        name = "RefundableToken";
        symbol = "BCC1";
        decimals = 18;
        owner = msg.sender;
        weiReceipt = 0x93E2Ec2BD2c5C17e1E44ABaCCa955a26B319c7Ca;
        tokenRate = 20;
        
        //1 million tokens to be generated
        //1 * (10**18)  = 1;
        _totalSupply = 1000000 * (10 ** uint256(decimals));
        
        //transfer total supply to owner
        _balances[owner] = _totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),owner,_totalSupply);
        
     }
     
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function tokenPrice() public view returns (uint256) {
       return tokenRate;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual  override returns (bool) {
        address sender = msg.sender;
        
        require(sender != address(0), "BCC1: transfer from the zero address");
        require(recipient != address(0), "BCC1: transfer to the zero address");
        require(_balances[sender] >= amount,"BCC1: transfer amount exceeds balance");

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
    function allowance(address tokenOwner, address spender) public view virtual  override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     * msg.sender: TokenOwner;
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override  returns (bool) {
        address tokenOwner = msg.sender;
        require(tokenOwner != address(0), "BCC1: approve from the zero address");
        require(spender != address(0), "BCC1: approve to the zero address");
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     * msg.sender: Spender
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address tokenOwner, address recipient, uint256 amount) public  virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender];
        require(_allowance > amount, "BCC1: transfer amount exceeds allowance");
        
        //deducting allowance
        _allowance = _allowance.sub(amount);
        
        //--- start transfer execution -- 
        
        //owner decrease balance
        _balances[tokenOwner] =_balances[tokenOwner].sub(amount); 
        
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(tokenOwner, recipient, amount);
        //-- end transfer execution--
        
        //decrease the approval amount;
        _allowances[tokenOwner][spender] = _allowance;
        
        emit Approval(tokenOwner, spender, amount);
        
        return true;
    }
    
    // restrict a function to only owner
     modifier onlyOwner(){
        require(msg.sender == owner,"BCC1: Only owner can execute this feature");
        _;
    }
    
    // transfer ownership from one to another
    function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    }
    
    // owner can assign a delegate to perform some function
     function setDelegate(address  _delegate) public onlyOwner returns (address) {
     delegate= _delegate;
    }
    
    // restrict a function to only owner or delegate
     modifier onlyOwnerOrDelegate(){
        require(msg.sender == owner || msg.sender == delegate ,"BCC1: Only owner or delegate can execute this feature");
        _;
    }
    
    // function to change token Rate
    function setRate(uint256  _tokenRate) public onlyOwnerOrDelegate returns (uint256) {
     tokenRate= _tokenRate;
    
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
    function buy(address payable buyer) public payable virtual returns (bool) {
        require(tx.origin == buyer); // to ensure transaction is initiated by EOA
        
        uint256 noOfTokensBuy = msg.value / tokenRate;// if needed, calculates the no of tokens bought
       
        uint256 weiReceived = msg.value; // wei paid by the buyer
       
        uint256 tokenUnitsInWeiToBuy = (msg.value.mul(10**decimals)).div(tokenRate); // calculates the smallest units of token bought
       
        uint256 tokenBuyingRate = tokenRate; // the rate at which the purchase was made
        
        uint256 tokensLeft = tokenUnitsInWeiToBuy; // tokens left after any refund
      
      _balances[buyer] =  _balances[buyer].add(tokenUnitsInWeiToBuy); // adds the tokens bought to buyer balance
      
      _balances[owner] =  _balances[owner].sub(tokenUnitsInWeiToBuy); // subtracts the tokens from the owner balance
      
      _balances[weiReceipt] =  _balances[weiReceipt].add(msg.value); //adds the wei received to the above defined weiReceipt address
        
        uint256 buyTime = block.timestamp; // records the time of purchase
        
        //update the struct with BuyDetails
        buyerDetails[buyer] = BuyDetails(buyTime, tokenUnitsInWeiToBuy, weiReceived, tokenBuyingRate, tokensLeft, noOfTokensBuy);
      
       return true;
      
    }

   // fallback gives warning: consider adding a receive ether function 
   receive() external payable{
       buy(msg.sender);
   }
   
   // function to calculate the amount of wei to refund at current token rate
   function refundCalc (address payable refundee, uint256 tokenRefund) public view returns (uint256) {
   uint256 y= (tokenRate * tokenRefund).mul(10**decimals); 
     return y;
      
        }     

   
   
   
   // function to transfer the wei calculated above to the refundee 
    function weiTransfer (address refundee, uint256 amount) public virtual {
        
        address sender = owner;
        
        require(sender != address(0), "BCC1: transfer from the zero address");
        require(refundee != address(0), "BCC1: transfer to the zero address");
        require(_balances[sender] >= amount,"BCC1: transfer amount exceeds balance");

        //decrease the balance of token sender account
        _balances[sender] = _balances[sender].sub(amount);
        
        //increase the balance of token recipient account
        _balances[refundee] = _balances[refundee].add(amount);

    }
    
  // function to refund wei against current token rate; uses refundCalc, transfer and weiTransfer functions within
    function refund(address payable refundee, uint256 tokenRefund ) public payable {
        require (msg.sender == refundee);
        
        // to ensure refund time falls within 1 month of refund period requirement
        require ( now <= (buyerDetails[refundee].buyTime + 2592000), "Return only possible when purchase time has passed 1 month");
        
        // to make sure withdrawal amount is available
        require (buyerDetails[refundee].tokensLeft >= tokenRefund, "No tokens left to refund"); 
        
        uint256 weiRefund = refundCalc(refundee, tokenRefund); // calcuate amount of wei to be refunded
        //  uint256 weiRefund = tokenUnitsInWeiToBuy/tokenRate;
        
        transfer(owner, tokenRefund); // transfer tokens from refundee to owner address
        
        weiTransfer(refundee, weiRefund); // transfer wei from weiReceipt address to refundee 
       
        //update the tokenLeft against the address: subtract the refunded amount of tokensLeft 
        buyerDetails[refundee].tokensLeft = buyerDetails[refundee].tokensLeft.sub(tokenRefund);
    }
        
}
       
