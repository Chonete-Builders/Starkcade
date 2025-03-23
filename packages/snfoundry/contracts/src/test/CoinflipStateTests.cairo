use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::{ContractAddress, contract_address_const};

// Define our own dispatcher for testing
#[starknet::interface]
trait ICoinflip<TContractState> {
    fn get_contract_balance(self: @TContractState) -> u256;
    fn get_min_bet(self: @TContractState) -> u256;
    fn get_max_bet(self: @TContractState) -> u256;
    fn get_house_edge(self: @TContractState) -> u256;
}

// Mock addresses
fn OWNER() -> ContractAddress {
    contract_address_const::<0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918>()
}

// Helper function to deploy the Coinflip contract with specific parameters
fn deploy_coinflip(min_bet: u256, max_bet: u256) -> ContractAddress {
    let contract_class = declare("Coinflip").unwrap().contract_class();
    let mut calldata = array![];
    
    // Add constructor parameters
    calldata.append(OWNER().into());
    calldata.append(min_bet.low.into());
    calldata.append(min_bet.high.into());
    calldata.append(max_bet.low.into());
    calldata.append(max_bet.high.into());
    
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

// Test Case 1: Test initial state after deployment
#[test]
fn test_initial_state() {
    // Deploy contract with specific min_bet and max_bet values
    let min_bet = 10000000000000000_u256; // 0.01 ETH
    let max_bet = 1000000000000000000_u256; // 1 ETH
    let contract_address = deploy_coinflip(min_bet, max_bet);
    
    // Create contract dispatcher
    let coinflip = ICoinflipDispatcher { contract_address };
    
    // Test view functions
    let retrieved_min_bet = coinflip.get_min_bet();
    let retrieved_max_bet = coinflip.get_max_bet();
    let house_edge = coinflip.get_house_edge();
    
    // Verify results
    assert(retrieved_min_bet == min_bet, 'Wrong min bet');
    assert(retrieved_max_bet == max_bet, 'Wrong max bet');
    assert(house_edge == 500, 'Wrong house edge default'); // Default house edge should be 500 (5%)
}

// Test Case 2: Test house_edge default value
#[test]
fn test_house_edge_default() {
    // Deploy contract
    let min_bet = 10000000000000000_u256; // 0.01 ETH
    let max_bet = 1000000000000000000_u256; // 1 ETH
    let contract_address = deploy_coinflip(min_bet, max_bet);
    
    // Create contract dispatcher
    let coinflip = ICoinflipDispatcher { contract_address };
    
    // Test initial house_edge
    let house_edge = coinflip.get_house_edge();
    assert(house_edge == 500, 'Wrong initial house_edge'); // Default is 500 (5%)
} 