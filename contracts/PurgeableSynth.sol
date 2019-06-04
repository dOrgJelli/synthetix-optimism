/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       PurgeableSynth.sol
version:    1.0
author:     Justin J. Moses
date:       2019-05-22

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Purgeable synths are a subclass of Synth that allows the owner
to exchange the Synth back into sUSD. These are used only for frozen
or deprecated synths.

-----------------------------------------------------------------
*/


pragma solidity 0.4.25;

import "./SafeDecimalMath.sol";
import "./ExchangeRates.sol";
import "./Synth.sol";


contract PurgeableSynth is Synth {

    using SafeDecimalMath for uint;

    uint public maxSupplyToPurgeInUSD;
    ExchangeRates public exchangeRates;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _proxy, TokenState _tokenState, Synthetix _synthetix, IFeePool _feePool,
        string _tokenName, string _tokenSymbol, address _owner, bytes4 _currencyKey, ExchangeRates _exchangeRates,
        uint _maxSupplyToPurgeInUSD
    )
        Synth(_proxy, _tokenState, _synthetix, _feePool, _tokenName, _tokenSymbol, _owner, _currencyKey)
        public
    {
        exchangeRates = _exchangeRates;
        maxSupplyToPurgeInUSD = _maxSupplyToPurgeInUSD;
    }


    /**
     * @notice Function that allows owner to exchange any number of holders back to sUSD (for frozen or deprecated synths)
     * @param addresses The list of holders to purge
     */
    function purge(address[] addresses)
        external
        optionalProxy_onlyOwner
    {
        uint maxSupplyToPurge = getMaxSupplyToPurge();

        // Only allow purge when total supply is lte the max or the rate is frozen in ExchangeRates
        require(
            totalSupply <= maxSupplyToPurge || exchangeRates.rateIsFrozen(currencyKey),
            "Cannot purge as total supply is above threshold and rate is not frozen."
        );

        for (uint8 i = 0; i < addresses.length; i++) {
            address holder = addresses[i];

            uint amountHeld = balanceOf(holder);

            if (amountHeld > 0) {
                synthetix.synthInitiatedExchange(holder, currencyKey, amountHeld, "sUSD", holder);
                emitPurged(holder, amountHeld);
            }

        }

    }

    /* ========== GETTERS ========== */

    function getMaxSupplyToPurge() public view returns (uint) {
        return maxSupplyToPurgeInUSD.multiplyDecimalRound(exchangeRates.rateForCurrency("sUSD"))
            .divideDecimalRound(exchangeRates.rateForCurrency(currencyKey));
    }

    /* ========== SETTERS ========== */

    function setMaxSupplyToPurgeInUSD(uint _maxSupplyToPurgeInUSD)
        external
        optionalProxy_onlyOwner
    {
        maxSupplyToPurgeInUSD = _maxSupplyToPurgeInUSD;
    }

    function setExchangeRates(ExchangeRates _exchangeRates)
        external
        optionalProxy_onlyOwner
    {
        exchangeRates = _exchangeRates;
    }

    /* ========== EVENTS ========== */

    event Purged(address indexed account, uint value);
    bytes32 constant PURGED_SIG = keccak256("Purged(address,uint256)");
    function emitPurged(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, PURGED_SIG, bytes32(account), 0, 0);
    }
}