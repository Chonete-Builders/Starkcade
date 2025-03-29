use contracts::Coinflip::{ICoinflipDispatcher, ICoinflipDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{cheat_caller_address, declare, CheatSpan, ContractClassTrait, DeclareResultTrait};
use starknet::{ContractAddress, contract_address_const};
use contracts::mock;


fn OWNER() -> ContractAddress {
    contract_address_const::<0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918>()
}


// #[starknet::interface]
// pub trait IERC20<TState> {
//     fn total_supply(self: @TState) -> u256;
//     fn balance_of(self: @TState, account: ContractAddress) -> u256;
//     fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
//     fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
//     fn transfer_from(
//         ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
//     ) -> bool;
//     fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;

// }

fn deploy_coinflip() -> ContractAddress {
    let contract_class = declare("Coinflip").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(OWNER()); // owner
    calldata.append_serde(10000000000000000_u256.into()); // min_bet (0.01 STRK)
    calldata.append_serde(100000000000000000_u256.into()); // max_bet (0.1 STRK)
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_mock_strk_erc20() -> ContractAddress {
    let contract_class = declare("SERC20").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(OWNER()); // owner
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_initial_config() {
    let coinflip_address = deploy_coinflip();
    let dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };

    let min_bet = dispatcher.get_min_bet();
    assert(min_bet == 10000000000000000, 'Incorrect min bet');
    
    let max_bet = dispatcher.get_max_bet();
    assert(max_bet == 100000000000000000, 'Incorrect max bet');
    
    let house_edge = dispatcher.get_house_edge();
    assert(house_edge == 500, 'Incorrect house edge'); // 5%
}

#[test]
fn test_place_bet() {
    let user = OWNER();
    // Deploy both contracts
    let coinflip_address = deploy_coinflip();
    let strk_address = deploy_mock_strk_erc20();

    let coinflip_dispatcher = ICoinflipDispatcher { contract_address: coinflip_address };
    let strk_dispatcher = IERC20Dispatcher { contract_address:  strk_address };
    
    // Verify initial balance (from constructor mint)
    let initial_balance = token_dispatcher.balance_of(user);
    assert(initial_balance == 2000000000000000000_u256, 'Initial balance incorrect'); // 2 STRK

    // Approve the contract to spend tokens
    cheat_caller_address(strk_address, user, CheatSpan::TargetCalls(1));
    strk_dispatcher.approve(coinflip_address, 1000000000000000000); // 1 STRK
    
    // Place a bet
    let bet_amount = 50000000000000000; // 0.05 STRK
    cheat_caller_address(coinflip_address, user, CheatSpan::TargetCalls(1));
    coinflip_dispatcher.place_bet(true, bet_amount);
    
    // Check pending bet
    let (selected_result, amount) = coinflip_dispatcher.get_pending_bet(user);
    assert(selected_result == true, 'Incorrect selected result');
    assert(amount == bet_amount, 'Incorrect bet amount');
    
    // Check token balance
    // let contract_balance = erc20_dispatcher.balance_of(coinflip_address);
    // assert(contract_balance == bet_amount, 'Contract should have received tokens');
}

