pragma solidity ^0.4.6;

import "./StandardToken.sol";
import "./SafeMath.sol";

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
contract FoolToken is StandardToken, SafeMath, Owned {

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

      if (!beneficiary.proxyPayment.value(amount)(msg.sender))
        throw;

      uint tokenCount = 1000 / msg.value;
      balances[msg.sender] += tokenCount;
      Issuance(msg.sender, tokenCount);
    }

     /// @dev Contract constructor function sets Giveth campaign
    function FoolToken(Campaign _beneficiary // address that receives ether)
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
