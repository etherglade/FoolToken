pragma solidity ^0.4.6;

import "./StandardToken.sol";
import "./SafeMath.sol";

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
contract FoolToken is StandardToken, SafeMath, Escapable {

    /*
     * Token meta data
     */
    string constant public name = "FoolToken";
    string constant public symbol = "POOP";
    uint8 constant public decimals = 3;
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

      uint tokenCount = div(1 ether, msg.value);
      balances[msg.sender] = add(balances[msg.sender], tokenCount);
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

