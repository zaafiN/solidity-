pragma solidity ^0.6.8;
//0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c
import "./IERC20.sol";
import "./SafeMath.sol";
// SafeMath library will allow to use arthemtic operation on Uint256
 
  contract PIAICBCCToken is IERC20{
    //Extending Uint256 with SafeMath Library.
    using SafeMath for uint256;
    
    //mapping to hold balances against EOA account
    mapping (address => uint256) private _balances;
    //mapping to hold approved allowance of token to certain address
    //       Owner               Spender    allowance
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // address public minter;
   // mapping (address => uint256) public balances;
   
   uint256 public timeTillTransactionLock;

    
    uint256 private _cap;
    //the amount of tokens in existence
    uint256 private _totalSupply;
    //owner
    address public owner;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
   

    constructor () public {
        name = "PIAIC-BCC Batch-1 Token";
        symbol = "BCC1";
        decimals = 4;
      //  minter = msg.sender;
        owner = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        
        
        //1 million tokens to be generated
        //1 * (10**18)  = 1;
        
        
        _totalSupply = 1000000 * (10 ** uint256(decimals));
        
        _cap = 20000000000;
        
        //transfer total supply to owner
        _balances[owner] = _totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),owner,_totalSupply);
     }
     //function capped() public view  returns (uint256){
     //    return _cap;
    //  }
     
     
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "BCC1: transfer from the zero address");
        require(recipient != address(0), "BCC1: transfer to the zero address");
        require(_balances[sender] > amount,"BCC1: transfer amount exceeds balance");
        
        _beforeTokenTransfer(sender,recipient, amount);

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
     /**
     * This function will allow owner to Mint more tokens.
     * 
     * Requirements:
     * - the caller must have Owner of Contract
     * - amount should be valid incremental value.
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function mint(address minter,uint256 amount) public onlyOwner returns(uint256) {
        require(amount > 0, "BCC1: Invalid amount.Minted amount should be greater than 0");
        require (minter != address(0), "BCC1: mint to the zero address");
        require(_totalSupply.add(amount) <= _cap, "BCC1: cap exceeded");
        _beforeTokenTransfer(address(0), minter, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[minter] = _balances[minter].add(amount);
        emit Transfer(address(0), minter, amount);
    
    }
    
    function lockTransferUntil(uint256 time) public {
        require(time>0 && time > now,"Invalid Time: time must be greater current");    
        timeTillTransactionLock = time; 
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal  virtual view { 
        require(timeTillTransactionLock <  now,"Transaction is Locked. Please try again" );
        
    }
    /*
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(timeTillTransactionLock <  now,"Transaction is Locked. Please try again" ); 
        ERC20.transfer(recipient,amount);
    }
    */
  

   
    modifier onlyOwner(){
        require(msg.sender == owner,"BCC1: Only owner can execute this feature");
        _;
    }
  }          
