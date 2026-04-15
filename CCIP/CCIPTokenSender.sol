// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// UGH. NEED OTHER CONTRACTS. BRING THEM HERE.
import {IRouterClient} from "@chainlink/contracts@1.3.0/src/v0.8/ccip/interfaces/IRouterClient.sol";
// ROUTER = BIG BRIDGE BETWEEN CHAINS. CHAINLINK MAKE.
import {Client} from "@chainlink/contracts@1.3.0/src/v0.8/ccip/libraries/Client.sol";
// CLIENT = HELPER TOOLS FOR MAKING MESSAGES. CHAINLINK MAKE.
import {IERC20} from "@chainlink/contracts@1.3.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
// IERC20 = TALK TO TOKEN. ANY TOKEN.
import {SafeERC20} from "@chainlink/contracts@1.3.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
// SAFE TRANSFER = NO LOSE TOKEN. SAFE.
import {Ownable} from "@openzeppelin/contracts@5.2.0/access/Ownable.sol";
// OWNABLE = ONLY CHIEF CAN DO SPECIAL THINGS

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

// THIS CONTRACT = SEND USDC TO OTHER CHAIN. ME BUILT IT.
contract CCIPTokenSender is Ownable {

    // ME USE SAFE TOOLS FOR TOKEN TRANSFER. NO FUMBLE.
    using SafeERC20 for IERC20;

    // OOGA BOOGA. IF NOT ENOUGH TOKEN, SCREAM THIS.
    error CCIPTokenSender__InsufficientBalance(IERC20 token, uint256 currentBalance, uint256 requiredAmount);
    // IF NOTHING TO TAKE OUT, SCREAM THIS.
    error CCIPTokenSender__NothingToWithdraw();

    // BIG BRIDGE ADDRESS. CHAINLINK LIVE HERE ON SEPOLIA.
    // https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#ethereum-testnet-sepolia
    IRouterClient private constant CCIP_ROUTER = IRouterClient(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);

    // LINK TOKEN. ME USE THIS TO PAY BRIDGE TOLL.
    // https://docs.chain.link/resources/link-token-contracts#ethereum-testnet-sepolia
    IERC20 private constant LINK_TOKEN = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    // USDC TOKEN. THE ROCK ME WANT TO THROW ACROSS BRIDGE.
    // https://developers.circle.com/stablecoins/docs/usdc-on-test-networks
    IERC20 private constant USDC_TOKEN = IERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);

    // THIS = ID OF OTHER CAVE (BASE CHAIN). VERY LONG NUMBER. NOT FORGET.
    // https://docs.chain.link/ccip/directory/testnet/chain/ethereum-testnet-sepolia-base-1
    uint64 private constant DESTINATION_CHAIN_SELECTOR = 10344971235874465080;

    // WHEN TOKEN GO ACROSS BRIDGE, FIRE SIGNAL SMOKE. TELL EVERYONE.
    event USDCTransferred(
        bytes32 messageId,               // UNIQUE ROCK MARK FOR THIS TRANSFER
        uint64 indexed destinationChainSelector, // WHICH CAVE WE SENT TO
        address indexed receiver,        // WHO CATCH ROCK ON OTHER SIDE
        uint256 amount,                  // HOW MUCH USDC GO
        uint256 ccipFee                  // HOW MUCH LINK ME PAY BRIDGE TROLL
    );

    // ME DEPLOY CONTRACT. ME BECOME CHIEF.
    constructor() Ownable(msg.sender) {}

    // MAIN FUNCTION. THROW USDC ROCK ACROSS BRIDGE TO OTHER CAVE.
    function transferTokens(
        address _receiver,   // WHO CATCH ROCK ON OTHER SIDE
        uint256 _amount      // HOW BIG ROCK
    )
        external
        returns (bytes32 messageId)  // BRIDGE GIVE BACK RECEIPT ROCK
    {
        // CHECK IF CALLER HAVE ENOUGH USDC. IF NOT, SCREAM.
        if (_amount > USDC_TOKEN.balanceOf(msg.sender)) {
            revert CCIPTokenSender__InsufficientBalance(USDC_TOKEN, USDC_TOKEN.balanceOf(msg.sender), _amount);
        }

        // MAKE LIST OF TOKENS ME WANT TO SEND. LIST HAVE ONE ROCK.
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);

        // DESCRIBE THE ROCK: USDC TOKEN, THIS MUCH.
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(USDC_TOKEN),
            amount: _amount
        });

        // PUT ROCK INTO LIST.
        tokenAmounts[0] = tokenAmount;

        // BUILD THE MESSAGE SCROLL TO SEND ACROSS BRIDGE.
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),  // WHO GET ROCK. ENCODE ADDRESS.
            data: "",                          // NO EXTRA MESSAGE. JUST ROCK.
            tokenAmounts: tokenAmounts,        // THE ROCKS
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})  // NO EXTRA GAS NEEDED ON OTHER SIDE
            ),
            feeToken: address(LINK_TOKEN)     // PAY TROLL WITH LINK
        });

        // ASK BRIDGE TROLL: HOW MUCH LINK YOU WANT?
        uint256 ccipFee = CCIP_ROUTER.getFee(
            DESTINATION_CHAIN_SELECTOR,
            message
        );

        // IF CONTRACT NOT HAVE ENOUGH LINK TO PAY TROLL, SCREAM.
        if (ccipFee > LINK_TOKEN.balanceOf(address(this))) {
            revert CCIPTokenSender__InsufficientBalance(LINK_TOKEN, LINK_TOKEN.balanceOf(address(this)), ccipFee);
        }

        // TELL LINK TOKEN: LET BRIDGE TROLL TAKE HIS FEE.
        LINK_TOKEN.approve(address(CCIP_ROUTER), ccipFee);

        // TAKE USDC ROCK FROM CALLER. PUT IN CONTRACT HAND FIRST.
        USDC_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);

        // TELL USDC TOKEN: LET BRIDGE TROLL TAKE THE ROCKS TOO.
        USDC_TOKEN.approve(address(CCIP_ROUTER), _amount);

        // Send CCIP Message
        // THROW SCROLL AND ROCKS ONTO BRIDGE. BRIDGE TAKE TO OTHER CAVE.
        messageId = CCIP_ROUTER.ccipSend(DESTINATION_CHAIN_SELECTOR, message);

        // FIRE SMOKE SIGNAL. TELL WORLD: TRANSFER HAPPENED.
        emit USDCTransferred(
            messageId,
            DESTINATION_CHAIN_SELECTOR,
            _receiver,
            _amount,
            ccipFee
        );
    }

    // ONLY CHIEF CAN DO THIS. TAKE ALL LEFTOVER USDC FROM CONTRACT.
    function withdrawToken(
        address _beneficiary  // SEND LEFTOVER ROCKS TO THIS CAVE ADDRESS
    ) public onlyOwner {
        // HOW MANY USDC ROCKS SITTING IN CONTRACT?
        uint256 amount = IERC20(USDC_TOKEN).balanceOf(address(this));

        // IF NO ROCKS, SCREAM. NOTHING TO TAKE.
        if (amount == 0) revert CCIPTokenSender__NothingToWithdraw();

        // GIVE ALL ROCKS TO BENEFICIARY. BYE ROCKS.
        IERC20(USDC_TOKEN).transfer(_beneficiary, amount);
    }
}