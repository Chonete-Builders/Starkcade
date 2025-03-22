use contracts::Coinflip::{ICoinflipDispatcher, ICoinflipDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare};
use starknet::{ContractAddress, contract_address_const};

// Test constants
const STRK_ADDRESS: felt252 = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
const DEFAULT_MIN_BET: u256 = 10000000000000000; // 0.01 STRK
const DEFAULT_MAX_BET: u256 = 1000000000000000000; // 1 STRK
const DEFAULT_HOUSE_EDGE: u256 = 500; // 5%

fn deploy_contract() -> ContractAddress {
    let contract_class = declare("Coinflip").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(contract_address_const::<0x123>()); // owner
    calldata.append_serde(DEFAULT_MIN_BET);
    calldata.append_serde(DEFAULT_MAX_BET);
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_initial_state() {
    let contract_address = deploy_contract();
    let dispatcher = ICoinflipDispatcher { contract_address };

    // Test initial state values
    assert(dispatcher.get_min_bet() == DEFAULT_MIN_BET, 'Incorrect initial min bet');
    assert(dispatcher.get_max_bet() == DEFAULT_MAX_BET, 'Incorrect initial max bet');
    assert(dispatcher.get_house_edge() == DEFAULT_HOUSE_EDGE, 'Incorrect initial house edge');
    assert(dispatcher.get_contract_balance() == 0, 'Contract should start with 0 balance');
}

#[test]
fn test_state_updates() {
    let contract_address = deploy_contract();
    let dispatcher = ICoinflipDispatcher { contract_address };
    let owner = contract_address_const::<0x123>();

    // Test updating min bet
    let new_min_bet = 20000000000000000; // 0.02 STRK
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.set_min_bet(new_min_bet);
    assert(dispatcher.get_min_bet() == new_min_bet, 'Min bet not updated correctly');

    // Test updating max bet
    let new_max_bet = 2000000000000000000; // 2 STRK
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.set_max_bet(new_max_bet);
    assert(dispatcher.get_max_bet() == new_max_bet, 'Max bet not updated correctly');

    // Test updating house edge
    let new_house_edge = 300; // 3%
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.set_house_edge(new_house_edge);
    assert(dispatcher.get_house_edge() == new_house_edge, 'House edge not updated correctly');
}

#[test]
#[should_panic]
fn test_invalid_state_updates() {
    let contract_address = deploy_contract();
    let dispatcher = ICoinflipDispatcher { contract_address };
    let owner = contract_address_const::<0x123>();

    // Test setting min bet higher than max bet
    let invalid_min_bet = DEFAULT_MAX_BET + 1;
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.set_min_bet(invalid_min_bet);

    // Test setting max bet lower than min bet
    let invalid_max_bet = DEFAULT_MIN_BET - 1;
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.set_max_bet(invalid_max_bet);

    // Test setting house edge too high (>10%)
    let invalid_house_edge = 1100;
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    dispatcher.set_house_edge(invalid_house_edge);
}

#[test]
fn test_contract_balance_updates() {
    let contract_address = deploy_contract();
    let dispatcher = ICoinflipDispatcher { contract_address };
    let user = contract_address_const::<0x456>();
    let strk_contract = contract_address_const::<STRK_ADDRESS>();
    let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract };

    // Setup: Give user some STRK tokens and approve contract
    let bet_amount = DEFAULT_MIN_BET;
    cheat_caller_address(strk_contract, user, CheatSpan::TargetCalls(1));
    strk_dispatcher.approve(contract_address, bet_amount);

    // Place a bet and check contract balance
    cheat_caller_address(contract_address, user, CheatSpan::TargetCalls(1));
    dispatcher.place_bet(true, bet_amount);
    assert(dispatcher.get_contract_balance() == bet_amount, 'Contract balance not updated after bet');

    // Flip coin and check contract balance
    cheat_caller_address(contract_address, user, CheatSpan::TargetCalls(1));
    dispatcher.flip_coin();
    // Balance should be 0 after payout (assuming user won)
    assert(dispatcher.get_contract_balance() == 0, 'Contract balance not updated after flip');
} 