// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract HogwartsHouses is VRFConsumerBaseV2Plus {
	// variables
	uint256 private constant ROLL_IN_PROGRESS = 42;
	uint256 s_subscriptionId;
	address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
	bytes32 s_keyHash =
		0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
	uint32 callbackGasLimit = 40000;
	uint16 requestConfirmations = 3;
	uint32 numWords = 1;
	mapping(uint256 => address) private s_students;
	mapping(address => uint256) private s_results;

	// events
	event SortingHatAsked(uint256 indexed requestId, address indexed student);
	event SortingHatAnswered(uint256 indexed requestId, uint256 indexed result);

	// errors
	error AlreadyAsked();
	error SortingHatNotAsked();
	error AskInProgress();

	// constructor
	constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
		s_subscriptionId = subscriptionId;
	}

	// askSortingHat function
	function askSortingHat() public returns (uint256 requestId) {
		address student = msg.sender;

		if (s_results[student] != 0) {
			revert AlreadyAsked();
		}

		// Will revert if subscription is not set and funded.
		requestId = s_vrfCoordinator.requestRandomWords(
			VRFV2PlusClient.RandomWordsRequest({
				keyHash: s_keyHash,
				subId: s_subscriptionId,
				requestConfirmations: requestConfirmations,
				callbackGasLimit: callbackGasLimit,
				numWords: numWords,
				extraArgs: VRFV2PlusClient._argsToBytes(
					VRFV2PlusClient.ExtraArgsV1({ nativePayment: false })
				)
			})
		);

		s_students[requestId] = student;
		s_results[student] = ROLL_IN_PROGRESS;
		emit SortingHatAsked(requestId, student);
	}

	// fulfillRandomWords function
	function fulfillRandomWords(
		uint256 requestId,
		uint256[] calldata randomWords
	) internal override {
		// transform the result to a number between 1 and 4 inclusively
		uint256 d4Value = (randomWords[0] % 4) + 1;

		// assign the transformed value to the address in the s_results mapping variable
		s_results[s_students[requestId]] = d4Value;

		// emitting event to signal that dice landed
		emit SortingHatAnswered(requestId, d4Value);
	}

	// house function
	function house(address player) public view returns (string memory) {
		// dice has not yet been rolled to this address
		if (s_results[player] == 0) {
			revert SortingHatNotAsked();
		}

		// not waiting for the result of a thrown dice
		if (s_results[player] == ROLL_IN_PROGRESS) {
			revert AskInProgress();
		}

		// returns the house name from the name list function
		return getHouseName(s_results[player]);
	}

	// getHouseName function
	function getHouseName(uint256 id) private pure returns (string memory) {
		// array storing the list of house's names
		string[4] memory houseNames = [
			"Gryffindor",
			"Hufflepuff",
			"Ravenclaw",
			"Slytherin"
		];

		// returns the house name given an index
		return houseNames[id - 1];
	}
}
