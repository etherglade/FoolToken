pragma solidity ^0.4.2;

/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
/// @title Abstract token contract - Functions to be implemented by token contracts.

contract AbstractToken {
    // This is not an abstract function, because solc won't recognize generated getter functions for public variables as functions
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = (a / b) ;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract StandardToken is AbstractToken, SafeMath {

    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender's tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        balances[msg.sender] = mul(balances[msg.sender], 10);
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        balances[_from] = mul(balances[_from], 10);
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read storage functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed, this `owner` is granted the exclusive right to execute 
///  functions tagged with the `onlyOwner` modifier
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier; the function body is inserted where the special symbol
    /// "_;" in the definition of a modifier appears.
    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    address public owner;

    /// @notice The Constructor assigns the address that deploys this contract
    /// to be `owner`
    function Owned() { owner = msg.sender;}

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
        NewOwner(msg.sender, _newOwner);
    }
    
    /// @dev Events make it easier to see that something has happend on the
    ///   blockchain
    event NewOwner(address indexed oldOwner, address indexed newOwner);
}
/// @dev `Escapable` is a base level contract built off of the `Owned`
///  contract that creates an escape hatch function to send its ether to
///  `escapeHatchDestination` when called by the `escapeHatchCaller` in the case
///  that something unexpected happens
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;

    /// @notice The Constructor assigns the `escapeHatchDestination` and the
    ///  `escapeHatchCaller`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract
    /// @param _escapeHatchCaller The address of a trusted account or contract to
    ///  call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller` cannot
    ///  move funds out of `escapeHatchDestination`
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    /// @dev The addresses preassigned the `escapeHatchCaller` role
    ///  is the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCallerOrOwner {
        if ((msg.sender != escapeHatchCaller)&&(msg.sender != owner))
            throw;
        _;
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    function escapeHatch() onlyEscapeHatchCallerOrOwner {
        uint total = this.balance;
        // Send the total balance of this contract to the `escapeHatchDestination`
        if (!escapeHatchDestination.send(total)) {
            throw;
        }
        EscapeHatchCalled(total);
    }
    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or contract to
    ///  call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller` cannot
    ///  move funds out of `escapeHatchDestination`
    function changeEscapeCaller(address _newEscapeHatchCaller) onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchCalled(uint amount);
}

/// @dev This is an empty contract to declare `proxyPayment()` to comply with
///  Giveth Campaigns so that tokens will be generated when donations are sent
contract Campaign {

    /// @notice `proxyPayment()` allows the caller to send ether to the Campaign and
    /// have the tokens created in an address of their choosing
    /// @param _owner The address that will hold the newly created tokens
    function proxyPayment(address _owner) payable returns(bool);
}

/// @title Token contract - Implements Standard Token Interface but adds Charity Support :)
/// @author Rishab Hegde - <contact@rishabhegde.com>
contract FoolToken is StandardToken, Escapable {

    /*
     * Token meta data
     */
    string constant public name = "FoolToken";
    string constant public symbol = "FOOL";
    uint8 constant public decimals = 18;
    bool public alive = true;
    Campaign public beneficiary; // expected to be a Giveth campaign
    address public owner = 0x506A24fBCb8eDa2EC7d757c943723cFB32a0682E;


    /*
     * Contract functions
     */
    /// @dev Allows user to create tokens if token creation is still going
    /// and cap was not reached. Returns token count.
    function fund()
      public
      payable 
    {
      if (!alive) throw;
      if (msg.value == 0) throw;

      if (!beneficiary.proxyPayment.value(msg.value)(msg.sender))
        throw;
    
      uint tokenCount = div(1 ether * 10 ** 18, msg.value);
      balances[msg.sender] = add(balances[msg.sender], tokenCount);
      totalSupply = add(totalSupply, tokenCount);
      Issuance(msg.sender, tokenCount);
    }

     /// @dev Contract constructor function sets Giveth campaign
    function FoolToken(
        Campaign _beneficiary,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    )
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
    {   
        beneficiary = _beneficiary;
    }

    /// @dev Allows founder to shut down the contract
    function killswitch()
      public
    {
      if (msg.sender != owner) throw;
      alive = false;
    }
}