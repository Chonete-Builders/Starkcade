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
    calldata.append_serde(100000000_u256); // max_bet (100 tokens)
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
