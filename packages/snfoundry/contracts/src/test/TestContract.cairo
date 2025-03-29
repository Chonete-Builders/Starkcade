use contracts::Coinflip::{ICoinflipDispatcher, ICoinflipDispatcherTrait};
use contracts::YourContract::{IYourContractDispatcher, IYourContractDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare};
use starknet::{ContractAddress, contract_address_const};

// Real contract address deployed on Sepolia
fn OWNER() -> ContractAddress {
    contract_address_const::<0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918>()
}
fn HYPOTHETICAL_OWNER_ADDR() -> ContractAddress {
    contract_address_const::<0x04a3189bdbc8716f416f7d54d9bf0d0f55ffb454bb89c547118d023a652277dd>()
}
fn STRK_CONTRACT_ADDRESS() -> ContractAddress {
    contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

const ETH_CONTRACT_ADDRESS: felt252 =
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract_class = declare(name).unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}


fn deploy_coinflip() -> ContractAddress {
    let contract_class = declare("Coinflip").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    calldata.append_serde(1000000_u256); // min_bet (1 token)
    calldata.append_serde(3_000_000_000_000_000_000_u256); // max_bet (100 tokens)
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_set_greetings() {
    let contract_address = deploy_contract("YourContract");

    let dispatcher = IYourContractDispatcher { contract_address };

    let current_greeting = dispatcher.greeting();
    let expected_greeting: ByteArray = "Building Unstoppable Apps!!!";
    assert(current_greeting == expected_greeting, 'Should have the right message');

    let new_greeting: ByteArray = "Learn Scaffold-Stark 2! :)";
    dispatcher.set_greeting(new_greeting.clone(), 0); // we transfer 0 eth
    assert(dispatcher.greeting() == new_greeting, 'Should allow set new message');
}

#[test]
#[fork("SEPOLIA_LATEST")]
fn test_transfer() {
    let user = OWNER();
    let eth_contract_address = contract_address_const::<ETH_CONTRACT_ADDRESS>();
    let your_contract_address = deploy_contract("YourContract");

    let your_contract_dispatcher = IYourContractDispatcher {
        contract_address: your_contract_address,
    };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: eth_contract_address };
    let amount_to_transfer = 500;
    cheat_caller_address(eth_contract_address, user, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(your_contract_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user, your_contract_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');

    let new_greeting: ByteArray = "Learn Scaffold-Stark 2! :)";

    cheat_caller_address(your_contract_address, user, CheatSpan::TargetCalls(1));
    your_contract_dispatcher.set_greeting(new_greeting.clone(), 500); // we transfer 0 eth
    assert(your_contract_dispatcher.greeting() == new_greeting, 'Should allow set new message');
}

#[test]
#[should_panic(expected: 'House edge too high')]
fn test_verify_house_edge_bug() {
    // Deploy the Coinflip contract
    let contract_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address };

    // Set caller as the owner
    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(2));

    // Verify initial house edge (default is 500 = 5%)
    let initial_edge = dispatcher.get_house_edge();
    assert(initial_edge == 500, 'Default edge should be 5%');

    // Try to set house edge to 15% (1500)
    dispatcher.set_house_edge(1500);
}

#[test]
fn test_set_valid_house_edge() {
    let contract_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address };

    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(1));

    // Set a valid house edge (8%)
    dispatcher.set_house_edge(800);

    let updated_edge = dispatcher.get_house_edge();
    assert(updated_edge == 800, 'House edge should be 8%');
}

#[test]
#[should_panic(expected: 'House edge too high')]
fn test_edge_case_house_edge_1001() {
    let contract_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address };

    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(1));

    // Try to set house edge to 10.01% (1001)
    // This should revert because it's just over the limit
    dispatcher.set_house_edge(1001);
}

#[test]
fn test_boundary_house_edge_1000() {
    let contract_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address };

    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(1));

    // Set house edge to exactly 10% (1000)
    // This should be accepted as it's exactly at the limit
    dispatcher.set_house_edge(1000);

    let updated_edge = dispatcher.get_house_edge();
    assert(updated_edge == 1000, 'House edge should be 10%');
}

#[test]
fn test_boundary_house_edge_999() {
    let contract_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address };

    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(1));

    // Set house edge to 9.99% (999)
    // This should be accepted as it's under the limit
    dispatcher.set_house_edge(999);

    let updated_edge = dispatcher.get_house_edge();
    assert(updated_edge == 999, 'House edge should be 9.99%');
}


/// - When no bets have been placed the leaderboard should return default entries.
#[test]
fn test_get_leaderboard_empty() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let leaderboard = dispatcher.get_leaderboard();
    // The leaderboard loop always appends MAX_LEADERBOARD_SIZE (10) entries.
    let len = leaderboard.len();
    assert(len == 10, 'Expected length of 10');

    let default_address: ContractAddress = contract_address_const::<0>();
    // Default mapping entries should be (0, 0) if not set.
    let default_entry: (ContractAddress, u256) = (default_address, 0);
    let mut i = 0;
    while i < len {
        let entry = leaderboard.at(i);
        assert(*entry == default_entry, 'Expected default entry');
        i += 1;
    }
}

/// - Insert three bets from three different users and verify the ordering.
#[test]
#[fork("SEPOLIA_LATEST")]
fn test_get_leaderboard_partial() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_CONTRACT_ADDRESS() };
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(coinflip_address, 10_000_000_000_000_000_000);

    // Simulate bet from user1 with 1 STRK
    let user1: ContractAddress = contract_address_const::<'user1'>();
    let amount_to_transfer = 1_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user1, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user1, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user1, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user1, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    // Simulate bet from user2 with 2 STRK
    let user2: ContractAddress = contract_address_const::<'user2'>();
    let amount_to_transfer = 2_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user2, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user2, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user2, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user2, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    // Simulate bet from user3 with 1.5 STRK
    let user3: ContractAddress = contract_address_const::<'user3'>();
    let amount_to_transfer = 1_500_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user3, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user3, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user3, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user3, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    let leaderboard = dispatcher.get_leaderboard();
    // Expected after updates:
    // Position 0: user2 with 2_000_000_000_000_000_000
    // Position 1: user3 with 1_500_000_000_000_000_000
    // Position 2: user1 with 1_000_000_000_000_000_000
    // Positions 3 to 9 remain as default (0, 0)
    let entry0 = leaderboard.at(0);
    let entry1 = leaderboard.at(1);
    let entry2 = leaderboard.at(2);
    assert(*entry0 == (user2, 2_000_000_000_000_000_000), 'User2 should be ranked first');
    assert(*entry1 == (user3, 1_500_000_000_000_000_000), 'User3 should be ranked second');
    assert(*entry2 == (user1, 1_000_000_000_000_000_000), 'User1 should be ranked third');

    let default_address: ContractAddress = contract_address_const::<0>();
    let default_entry: (ContractAddress, u256) = (default_address, 0);
    let mut i = 3;
    while i < leaderboard.len() {
        assert(*leaderboard.at(i) == default_entry, 'Remaining should be default');
        i += 1;
    }
}

/// - Insert 10 bets from distinct users with various amounts and verify the ordering is sorted
/// descending.
#[test]
#[fork("SEPOLIA_LATEST")]
fn test_get_leaderboard_full() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_CONTRACT_ADDRESS() };
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(coinflip_address, 10_000_000_000_000_000_000);
    // Define 10 bets: (user, bet_amount)
    let users = array![contract_address_const::<'user1'>(), contract_address_const::<'user2'>(),];
    let bets = array![800_000_000_000_000_000_u256, 1_000_000_000_000_000_000];
    let n = bets.len();
    // Place each bet from a different user.
    for i in 0
        ..n {
            let user: ContractAddress = *users[i];
            let amount_to_transfer = *bets[i];
            cheat_caller_address(
                STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
            );
            erc20_dispatcher.transfer(user, amount_to_transfer);
            cheat_caller_address(STRK_CONTRACT_ADDRESS(), user, CheatSpan::TargetCalls(1));
            erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
            let approved_amount = erc20_dispatcher.allowance(user, coinflip_address);
            assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
            cheat_caller_address(coinflip_address, user, CheatSpan::TargetCalls(2));
            dispatcher.place_bet(true, amount_to_transfer);
            dispatcher.flip_coin();
        };
    let leaderboard = dispatcher.get_leaderboard();
    // Expected descending order:
    // Position 0: user3 with 1_100_000_000_000_000_000
    // Position 1: user2 with 1_000_000_000_000_000_000
    // Position 2: user1 with 800_000_000_000_000_000
    // Positions 3 to 9 remain as default (0, 0)

    let default_address: ContractAddress = contract_address_const::<0>();
    let default_entry: (ContractAddress, u256) = (default_address, 0);
    let expected = array![
        (*users[1], *bets[1]),
        (*users[0], *bets[0]),
        default_entry,
        default_entry,
        default_entry,
        default_entry,
        default_entry,
        default_entry,
        default_entry,
        default_entry,
    ];

    // Verify each leaderboard entry matches expectation.
    let mut i = 0;
    while i < 10 {
        let (actual_user, actual_amt) = *leaderboard.at(i);
        let (exp_user, exp_amt) = *expected[i];
        assert(actual_user == exp_user, 'User should match');
        assert(actual_amt == exp_amt, 'Amount should match');
        i += 1;
    };
}

#[test]
fn test_get_recent_flips_empty() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };

    let recent_flips = dispatcher.get_recent_flips();
    assert(recent_flips.len() == 0, 'Expected no recent flips');
}

#[test]
fn test_get_user_flips_empty() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };

    let user = OWNER();
    let user_flips = dispatcher.get_user_flips(user);
    assert(user_flips.len() == 0, 'Expected no user flips');
}

#[test]
#[fork("SEPOLIA_LATEST")]
fn test_get_recent_flips_single() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_CONTRACT_ADDRESS() };
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(coinflip_address, 10_000_000_000_000_000_000);

    // Simulate bet from user1 with 1 STRK
    let user1: ContractAddress = contract_address_const::<'user1'>();
    let amount_to_transfer = 1_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user1, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user1, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user1, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user1, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    let recent_flips = dispatcher.get_recent_flips();
    assert(recent_flips.len() == 1, 'Expected exactly one');

    let (flip_user, _, bet_amount) = *recent_flips.at(0);
    assert(flip_user == user1, 'should record the correct user');
    assert(bet_amount == amount_to_transfer, 'Bet amount should be equal');
}

#[test]
#[fork("SEPOLIA_LATEST")]
fn test_get_user_flips_single() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_CONTRACT_ADDRESS() };
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(coinflip_address, 10_000_000_000_000_000_000);

    // Simulate bet from user1 with 1 STRK
    let user1: ContractAddress = contract_address_const::<'user1'>();
    let amount_to_transfer = 1_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user1, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user1, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user1, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user1, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    let user_flips = dispatcher.get_user_flips(user1);
    assert(user_flips.len() == 1, 'Expected exactly one');

    let (_, bet_amount) = *user_flips.at(0);
    assert(bet_amount == amount_to_transfer, 'amount should match');
}

#[test]
#[fork("SEPOLIA_LATEST")]
fn test_get_user_flips_multiple() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_CONTRACT_ADDRESS() };
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(coinflip_address, 10_000_000_000_000_000_000);
    let user1: ContractAddress = contract_address_const::<'user1'>();
    let amount_to_transfer = 1_000_000_000_000_000_000;

    // First bet
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user1, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user1, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user1, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user1, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    // Second bet
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user1, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user1, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user1, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user1, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    let user_flips = dispatcher.get_user_flips(user1);
    assert(user_flips.len() == 2, 'Expected two user flip entries');

    let (_, amount1) = *user_flips.at(0);
    let (_, amount2) = *user_flips.at(1);

    assert(amount1 == amount_to_transfer, 'amount should be equal');
    assert(amount2 == amount_to_transfer, 'amount should be equal');
}

#[test]
#[fork("SEPOLIA_LATEST")]
fn test_get_recent_flips_multiple() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_CONTRACT_ADDRESS() };
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(coinflip_address, 10_000_000_000_000_000_000);

    // Simulate bet from user1 with 1 STRK
    let user1: ContractAddress = contract_address_const::<'user1'>();
    let amount_to_transfer = 1_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user1, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user1, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user1, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user1, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    // Simulate bet from user2 with 2 STRK
    let user2: ContractAddress = contract_address_const::<'user2'>();
    let amount_to_transfer = 2_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user2, amount_to_transfer);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user2, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount_to_transfer);
    let approved_amount = erc20_dispatcher.allowance(user2, coinflip_address);
    assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    cheat_caller_address(coinflip_address, user2, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount_to_transfer);
    dispatcher.flip_coin();

    let recent_flips = dispatcher.get_recent_flips();
    assert(recent_flips.len() == 2, 'Expected two recent flips');

    let (flip_user1, _, amount1) = *recent_flips.at(0);
    let (flip_user2, _, amount2) = *recent_flips.at(1);

    assert(flip_user1 == user1, 'flip should be from user1');
    assert(amount1 == 1_000_000_000_000_000_000, 'Bet amount should be equal');

    assert(flip_user2 == user2, 'flip should be from user2');
    assert(amount2 == 2_000_000_000_000_000_000, 'Bet amount should be equal');
}


/// Test: get_user_flips for a user that never placed a bet.
#[test]
fn test_get_user_flips_nonexistent() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };

    // Use a user address that never placed a bet.
    let non_existing_user: ContractAddress = contract_address_const::<'nonexistent'>();
    let user_flips = dispatcher.get_user_flips(non_existing_user);
    assert(user_flips.len() == 0, 'Expected no flips');
}

/// Test: Recent flips ordering after multiple bets (including duplicate user flips).
#[test]
#[fork("SEPOLIA_LATEST")]
fn test_get_recent_flips_after_multiple() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_CONTRACT_ADDRESS() };
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    // Fund the coinflip contract.
    erc20_dispatcher.transfer(coinflip_address, 10_000_000_000_000_000_000);

    // Bet 1: user1.
    let user1: ContractAddress = contract_address_const::<'user1'>();
    let amount1 = 1_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user1, amount1);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user1, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount1);
    let _ = erc20_dispatcher.allowance(user1, coinflip_address);
    cheat_caller_address(coinflip_address, user1, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount1);
    dispatcher.flip_coin();

    // Bet 2: user2.
    let user2: ContractAddress = contract_address_const::<'user2'>();
    let amount2 = 2_000_000_000_000_000_000;
    cheat_caller_address(
        STRK_CONTRACT_ADDRESS(), HYPOTHETICAL_OWNER_ADDR(), CheatSpan::TargetCalls(1)
    );
    erc20_dispatcher.transfer(user2, amount2);
    cheat_caller_address(STRK_CONTRACT_ADDRESS(), user2, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(coinflip_address, amount2);
    let _ = erc20_dispatcher.allowance(user2, coinflip_address);
    cheat_caller_address(coinflip_address, user2, CheatSpan::TargetCalls(2));
    dispatcher.place_bet(true, amount2);
    dispatcher.flip_coin();

    let recent_flips = dispatcher.get_recent_flips();
    assert(recent_flips.len() == 2, 'Expected two recent flips');
    // Verify the order: [user1 (first bet), user2, user1 (second bet)]
    let (flip1_user, _, amt1_out) = *recent_flips.at(0);
    let (flip2_user, _, amt2_out) = *recent_flips.at(1);
    assert(flip1_user == user1, 'First flip should be from user1');
    assert(amt1_out == amount1, 'First flip amount should match');
    assert(flip2_user == user2, 'Second flip should be from u2');
    assert(amt2_out == amount2, 'Second flip amount should match');
}
