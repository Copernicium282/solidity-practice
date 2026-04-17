// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Deploy on Sepolia
// @dev i add caveman explain cause me no understand :)

// UGH. ME NEED CHAINLINK. CHAINLINK TALK TO OUTSIDE WORLD FOR ME.
import {FunctionsClient} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// ME CONTRACT. ME INHERIT FROM CHAINLINK CLIENT. CHAINLINK DO HARD WORK.
contract FunctionsConsumer is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    // ME REMEMBER LAST CITY THAT SENT BACK WEATHER. GOOD CITY.
    string public s_lastCity;
    // ME REMEMBER CITY ME ASKED ABOUT. NOT ANSWERED YET. ME WAIT.
    string public s_requestedCity;
    // ME REMEMBER HOT OR COLD NUMBER. VERY IMPORTANT.
    string public s_lastTemperature;

    // ME KEEP TICKET NUMBER SO ME KNOW WHICH ANSWER IS MINE
    bytes32 public s_lastRequestId;
    // RAW ANSWER FROM OUTSIDE. ME NOT ALWAYS UNDERSTAND. BYTES SCARY.
    bytes public s_lastResponse;
    // IF SOMETHING GO WRONG, ERROR GO HERE. ME SAD THEN.
    bytes public s_lastError;

    // THIS WHERE CHAINLINK LIVE ON SEPOLIA. ME NOT CHANGE. ME TRUST.
    address constant ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    // THIS NAME OF CHAINLINK TRIBE. IN ROCK LANGUAGE (HEX).
    bytes32 constant DON_ID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    // HOW MUCH GAS ME GIVE FOR ANSWER TO COME BACK. NOT TOO LITTLE. NOT TOO MUCH.
    uint32 constant GAS_LIMIT = 300000;
    // THIS MAGIC WORDS. CHAINLINK MAN RUN THIS CODE OUTSIDE BLOCKCHAIN. ME TRUST CHAINLINK MAN.
    string public constant SOURCE =
        "const city = args[0];"                                    // CITY NAME ME SENT
        "const apiResponse = await Functions.makeHttpRequest({"    // GO FETCH WEATHER FROM SKY GOD (wttr.in)
        "url: `https://wttr.in/${city}?format=3&m`,"              // THIS WHERE WEATHER LIVE
        "responseType: 'text'"                                     // BRING BACK AS WORDS, NOT ROCK
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"                           // SKY GOD ANGRY. ME CRY.
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data);";                    // WRAP ANSWER IN BLOCKCHAIN CLOTH. SEND BACK.

    // WHEN ANSWER COME BACK, ME SHOUT THIS EVENT. EVERYONE HEAR.
    event Response(
        bytes32 indexed requestId,
        string temperature,
        bytes response,
        bytes err
    );

    // IF WRONG TICKET COME BACK, ME VERY CONFUSED. ME THROW ERROR.
    error UnexpectedRequestID(bytes32 requestId);

    // ME BORN. ME TELL CHAINLINK WHO ME IS.
    constructor() FunctionsClient(ROUTER) {}

    // ME ASK: "HOW HOT IS CITY?" ME GIVE CITY NAME AND LINK COINS. ME WAIT.
    function getTemperature(
        string memory city,
        uint64 subscriptionId
    ) external returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(SOURCE); // PUT MAGIC WORDS IN REQUEST BASKET

        string[] memory args = new string[](1);
        args[0] = city;
        req.setArgs(args); // STUFF CITY NAME INTO BASKET TOO

        // THROW BASKET TO CHAINLINK. CHAINLINK RUN. ME WAIT BY FIRE.
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            GAS_LIMIT,
            DON_ID
        );

        // REMEMBER CITY ME ASKED ABOUT. ME NOT FORGET.
        s_requestedCity = city;
        return s_lastRequestId;
    }

    // CHAINLINK MAN COME BACK WITH ANSWER. ME VERY EXCITED.
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        // CHECK TICKET. IF NOT MY TICKET, ME CONFUSED. ME REVERT.
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        // STORE ERROR (IF ANY). HOPE IT EMPTY. ME SCARED.
        s_lastError = err;
        // STORE RAW ANSWER. UGLY BUT HONEST.
        s_lastResponse = response;

        // TURN BYTES INTO WORDS ME CAN READ. AHH MUCH BETTER.
        s_lastTemperature = string(response);
        // NOW CITY IS CONFIRMED. CITY GRADUATE. CITY MOVE TO s_lastCity.
        s_lastCity = s_requestedCity;

        // SHOUT TO EVERYONE: "ME GOT WEATHER! COME SEE!"
        emit Response(requestId, s_lastTemperature, s_lastResponse, s_lastError);
    }
}